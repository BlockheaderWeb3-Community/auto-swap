export const tokenAddresses: {
  [key in "ETH" | "BTC" | "USDC" | "USDT" | "STRK"]: string;
} = {
  ETH: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
  BTC: "0x00da114221cb83fa859dbdb4c44beeaa0bb37c7537ad5ae66fe5e0efd20e6eb3",
  USDC: "0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8",
  USDT: "0x068f5c6a61780768455de69077e07e89787839bf8166decfbf92b645209c0fb8",
  STRK: "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d",
};

export const tokenPrices: { [key in keyof typeof tokenAddresses]: number } = {
  ETH: 2435,
  BTC: 1,
  USDC: 1.01,
  USDT: 0.99,
  STRK: 0.48,
};

export const tokenImages: { [key in keyof typeof tokenAddresses]: string } = {
  ETH: "/coin-logos/eth-logo.png",
  BTC: "/coin-logos/btc-logo.png",
  USDC: "/coin-logos/usdc-logo.png",
  USDT: "/coin-logos/usdt-logo.png",
  STRK: "/coin-logos/strk-logo.png",
};

export type Token = keyof typeof tokenAddresses;
