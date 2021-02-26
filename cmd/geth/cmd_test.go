package main

import (
	"encoding/json"
	"fmt"
	"github.com/ethereum/go-ethereum/cmd/utils"
	"github.com/ethereum/go-ethereum/core"
	"github.com/ethereum/go-ethereum/node"
	"github.com/ethereum/go-ethereum/p2p/enode"
	"github.com/ethereum/go-ethereum/params"
	"net"
	"os"
	"path"
	"strconv"
	"strings"
	"testing"
)

func Test_tomlconfig(t *testing.T) {
	//todo test marshal toml
	cfgFile := "../../sample-config.toml"
	var config gethConfig
	err := loadConfig(cfgFile, &config)
	if err != nil {
		panic(err)
	}

	_, err = tomlSettings.Marshal(config)
	if err != nil {
		fmt.Println("==============")
		panic(err)
	}
}

func Test_initnetworkcmd(t *testing.T) {

	size := 2
	cfgFile := "../../sample-config.toml"
	initDir := "./init"
	addrStr := "127.0.0.1:2000,127.0.0.1:2001"
	if len(cfgFile) == 0 {
		utils.Fatalf("config file is required")
	}
	var addrs []string
	if len(addrStr) != 0 {
		addrs = strings.Split(addrStr, ",")
		if len(addrs) != size {
			utils.Fatalf("mismatch of size and length of ips")
		}
		for i := 0; i < size; i++ {
			ip, port, err := net.SplitHostPort(addrs[i])
			_, err = net.ResolveIPAddr("", ip)
			if err != nil {
				utils.Fatalf("invalid format of ip")
				panic(err)
			}

			iport, err := strconv.Atoi(port)
			if err != nil {
				utils.Fatalf("invalid format of port")
				panic(err)
			}
			if iport < 1024 || iport > 49151 {
				utils.Fatalf("invalid port")
				panic(err)
			}
		}
	} else {
		addrs = make([]string, size)
		for i := 0; i < size; i++ {
			addrs[i] = "127.0.0.1:30311"
		}
	}

	// Make sure we have a valid genesis JSON
	genesisPath := "../../mxctest.json"
	if len(genesisPath) == 0 {
		utils.Fatalf("Must supply path to genesis JSON file")
	}
	file, err := os.Open(genesisPath)
	if err != nil {
		utils.Fatalf("Failed to read genesis file: %v", err)
	}
	defer file.Close()

	genesis := new(core.Genesis)
	if err := json.NewDecoder(file).Decode(genesis); err != nil {
		utils.Fatalf("invalid genesis file: %v", err)
	}
	enodes := make([]*enode.Node, size)

	// load config
	var config gethConfig
	err = loadConfig(cfgFile, &config)
	if err != nil {
		panic(err)
	}
	config.Eth.Genesis = genesis
	config.Eth.Genesis.Config.Ethash = &params.EthashConfig{}

	stack, err := node.New(&config.Node)
	if err != nil {
		panic(err)
	}

	for i := 0; i < size; i++ {

		stack.Config().DataDir = path.Join(initDir, fmt.Sprintf("node%d", i))
		pk := stack.Config().NodeKey()
		ip, port, _ := net.SplitHostPort(addrs[i])
		iport, _ := strconv.Atoi(port)
		enodes[i] = enode.NewV4(&pk.PublicKey, net.ParseIP(ip), iport, iport)
	}

	for i := 0; i < size; i++ {
		ip, _, _ := net.SplitHostPort(addrs[i])
		config.Node.HTTPHost = ip
		config.Node.P2P.StaticNodes = make([]*enode.Node, size-1)
		for j := 0; j < i; j++ {
			config.Node.P2P.StaticNodes[j] = enodes[j]
		}
		for j := i + 1; j < size; j++ {
			config.Node.P2P.StaticNodes[j-1] = enodes[j]
		}

		fmt.Printf("%v\n", config.Eth.Ethash)

		out, err := tomlSettings.Marshal(config)
		if err != nil {
			fmt.Println("==============")
			panic(err)
		}
		dump, err := os.OpenFile(path.Join(initDir, fmt.Sprintf("node%d", i), "config.toml"), os.O_RDWR|os.O_CREATE|os.O_TRUNC, 0644)
		if err != nil {
			panic(err)
		}
		defer dump.Close()
		dump.Write(out)
	}

}
