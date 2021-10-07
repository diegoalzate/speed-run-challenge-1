import Web3Modal, { ICoreOptions } from 'web3modal';

import { INFURA_ID } from '~~/models/constants/constants';

import Portis from '@portis/web3';
import Fortmatic from 'fortmatic';
// @ts-ignore
import WalletLink from 'walletlink';
import WalletConnectProvider from '@walletconnect/ethereum-provider';
import Authereum from 'authereum';
import { ConnectToStaticJsonRpcProvider } from '~~/helpers/StaticJsonRpcProviderConnector';
import { JsonRpcProvider, StaticJsonRpcProvider } from '@ethersproject/providers';
import { localNetworkInfo } from '~~/config/providersConfig';

const portis = {
  display: {
    logo: 'https://user-images.githubusercontent.com/9419140/128913641-d025bc0c-e059-42de-a57b-422f196867ce.png',
    name: 'Portis',
    description: 'Connect to Portis App',
  },
  package: Portis,
  options: {
    id: '6255fb2b-58c8-433b-a2c9-62098c05ddc9',
  },
};
const formatic = {
  package: Fortmatic,
  options: {
    key: 'pk_live_5A7C91B2FC585A17',
  },
};

// Coinbase walletLink init
const walletLink = new WalletLink({
  appName: 'coinbase',
});

// WalletLink provider
const walletLinkProvider = walletLink.makeWeb3Provider(`https://mainnet.infura.io/v3/${INFURA_ID}`, 1);

const coinbaseWalletLink = {
  display: {
    logo: 'https://play-lh.googleusercontent.com/PjoJoG27miSglVBXoXrxBSLveV6e3EeBPpNY55aiUUBM9Q1RCETKCOqdOkX2ZydqVf0',
    name: 'Coinbase',
    description: 'Connect to your Coinbase Wallet (not coinbase.com)',
  },
  package: walletLinkProvider,
  connector: async (provider: any, _options: any) => {
    await provider.enable();
    return provider;
  },
};

const authereum = {
  package: Authereum,
};

//network: 'mainnet', // Optional. If using WalletConnect on xDai, change network to "xdai" and add RPC info below for xDai chain.
const walletConnectEthereum = {
  package: WalletConnectProvider,
  options: {
    bridge: 'https://polygon.bridge.walletconnect.org',
    infuraId: INFURA_ID,
    rpc: {
      1: `https://mainnet.infura.io/v3/${INFURA_ID}`,
      42: `https://kovan.infura.io/v3/${INFURA_ID}`,
      100: 'https://dai.poa.network',
    },
  },
};

// const torus = {
//   package: Torus,
//   options: {
//     networkParams: {
//       host: 'https://localhost:8545',
//       chainId: 1337,
//       networkId: 1337, // optional
//     },
//     config: {
//       buildEnv: 'development',
//     },
//   },
// };

const localhostStaticConnector = {
  display: {
    logo: 'https://avatars.githubusercontent.com/u/56928858?s=200&v=4',
    name: 'Burner Wallet',
    description: 'Connect to your localhost with a burner wallet 🔥',
  },
  package: StaticJsonRpcProvider,
  connector: ConnectToStaticJsonRpcProvider,
  options: {
    chainId: localNetworkInfo.chainId,
    rpc: {
      [localNetworkInfo.chainId]: localNetworkInfo.rpcUrl,
    },
  },
};

export const web3ModalConfig: Partial<ICoreOptions> = {
  cacheProvider: true,
  theme: 'light',
  providerOptions: {
    'custom-localhost': localhostStaticConnector,
    walletconnect: walletConnectEthereum,
    portis: portis,
    fortmatic: formatic,
    //torus: torus,
    authereum: authereum,
    'custom-walletlink': coinbaseWalletLink,
  },
};
