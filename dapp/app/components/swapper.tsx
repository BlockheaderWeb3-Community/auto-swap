"use client";
import React, { useState, useEffect } from "react";
import { useAccount } from "@starknet-react/core";
import {
  ArrowUpDown,
  ChevronDown,
  ChevronUp,
  RefreshCcw,
  X,
} from "lucide-react";

const tokenAddresses: {
  [key in "ETH" | "BTC" | "USDC" | "USDT" | "STRK"]: string;
} = {
  ETH: "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7",
  BTC: "0x00da114221cb83fa859dbdb4c44beeaa0bb37c7537ad5ae66fe5e0efd20e6eb3",
  USDC: "0x053c91253bc9682c04929ca02ed00b3e423f6710d2ee7e0d5ebb06f3ecf368a8",
  USDT: "0x068f5c6a61780768455de69077e07e89787839bf8166decfbf92b645209c0fb8",
  STRK: "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d",
};
const tokenPrices: { [key in keyof typeof tokenAddresses]: number } = {
  ETH: 2435,
  BTC: 1,
  USDC: 1.01,
  USDT: 0.99,
  STRK: 0.48,
};

const tokenImages: { [key in keyof typeof tokenAddresses]: string } = {
  ETH: "/coin-logos/eth-logo.png",
  BTC: "/coin-logos/btc-logo.png",
  USDC: "/coin-logos/usdc-logo.png",
  USDT: "/coin-logos/usdt-logo.png",
  STRK: "/coin-logos/strk-logo.png",
};

const CustomSelect: React.FC<{
  selectedToken: keyof typeof tokenAddresses;
  onTokenSelect: (token: keyof typeof tokenAddresses) => void;
}> = ({ selectedToken, onTokenSelect }) => {
  const [isOpen, setIsOpen] = useState(false);
  const tokens = Object.keys(tokenAddresses) as Array<
    keyof typeof tokenAddresses
  >;

  const handleSelect = (token: string) => {
    onTokenSelect(token as keyof typeof tokenAddresses);
    setIsOpen(false);
  };

  return (
    <div className="relative h-[10.45px] w-[25%] md:h-[40px] md:w-[200px]">
      <div
        className="bg-[#131313] text-[#F7F7F7] border-[1px] border-[#1E1E1E] font-semibold flex h-full w-full cursor-pointer items-center justify-between gap-2 rounded-sm px-2 py-[6px] text-[10px] md:gap-2 md:rounded-full md:text-[16px]"
        onClick={() => setIsOpen(!isOpen)}
      >
        <span className="flex items-center gap-x-1 text-sm">
          <img
            src={tokenImages[selectedToken]}
            className="w-7 h-7"
            alt={selectedToken}
          />
          {selectedToken}
        </span>
        <span>
          {isOpen ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
        </span>
      </div>

      {isOpen && (
        <div className="absolute left-0 top-12 z-10 w-full rounded-md bg-[#131313] border-[1px] border-[#1E1E1E] text-[8.97px] text-[#f7f7f7] shadow-lg md:text-[16px]">
          {tokens.map((token) => (
            <button
              key={token}
              className="flex items-center gap-2 cursor-pointer bg-[#131313] p-2  w-full rounded-sm border border-transparent hover:bg-opacity-90 hover:border-[#1E1E1E] hover:border transition-all duration-300 ease-in-out"
              onClick={() => handleSelect(token)}
            >
              <img
                src={tokenImages[token]}
                className="w-5 h-5"
                alt={`${token} logo`}
              />
              <span className="font-semibold">{token}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
};

const Swapper = () => {
  const [fromToken, setFromToken] =
    useState<keyof typeof tokenAddresses>("ETH");
  const [toToken, setToToken] = useState<keyof typeof tokenAddresses>("USDT");
  const [amount, setAmount] = useState("");
  const [equivalent, setEquivalent] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState("");
  const [rate, setRate] = useState(0);

  const { address } = useAccount();

  useEffect(() => {
    updateRate();
  }, [fromToken, toToken]);

  useEffect(() => {
    if (amount && rate) {
      const numericAmount = parseFloat(amount);
      if (!isNaN(numericAmount)) {
        setEquivalent((numericAmount * rate).toFixed(6));
      } else {
        setEquivalent("0");
      }
    } else {
      setEquivalent("0");
    }
  }, [amount, rate]);

  const updateRate = () => {
    const fromPrice = tokenPrices[fromToken];
    const toPrice = tokenPrices[toToken];
    const newRate = toPrice / fromPrice;
    setRate(newRate);
  };

  const numberRegex = /^[0-9]*[.,]?[0-9]*$/;

  const handleSwap = async () => {
    if (!address) return;

    setIsLoading(true);
    setError("");

    // Simulate a delay for the swap process
    setTimeout(() => {
      try {
        const swappedAmount = parseFloat(amount) * rate;
        console.log(
          `Swapped ${amount} ${fromToken} for ${swappedAmount.toFixed(
            6
          )} ${toToken}`
        );
        setAmount("");
        setEquivalent("0");
        setError("");
      } catch (error) {
        console.error("Swap failed:", error);
        setError("Swap failed. Please try again.");
      } finally {
        setIsLoading(false);
      }
    }, 2000);
  };

  const handleTokenSwap = () => {
    const temp = fromToken;
    setFromToken(toToken);
    setToToken(temp);
  };

  const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    if (numberRegex.test(value)) {
      setAmount(value);
    }
  };

  return (
    <div className="flex w-full cursor-pointer flex-col text-[#F7F7F7] rounded-[48px] p-[18px] md:w-[464px] md:p-[2rem] bg-[#0F0F0F] border-[1px] border-[#1E1E1E]">
      <form className="m-0">
        <div className="relative flex w-full flex-col items-center">
          <div className="mb-4 flex w-full flex-col">
            <div className="rounded-[24px] px-[10px] py-[10px] md:px-[24px] md:py-[20px] border border-[#1E1E1E] bg-[#131313]">
              <h3 className="mb-2 text-[9.97px] md:text-[16px] text-left text-[#F7F7F7] text-base">
                From
              </h3>
              <div className="flex justify-between">
                <div className="flex flex-col items-start">
                  <input
                    type="text"
                    value={amount}
                    placeholder="0"
                    onChange={handleAmountChange}
                    className="w-[45%] bg-transparent text-[18.59px] font-[700] outline-none md:w-[75%] md:text-[32px]"
                  />
                  <p className="ml-[2px] max-w-[45%] overflow-hidden text-ellipsis whitespace-nowrap text-[9.97px] font-[600] md:text-[16px]">
                    = ${(parseFloat(amount || "0") * rate).toFixed(3)}
                  </p>
                </div>
                <CustomSelect
                  selectedToken={fromToken}
                  onTokenSelect={setFromToken}
                />
              </div>
            </div>
          </div>

          <button
            type="button"
            onClick={handleTokenSwap}
            className="absolute top-[44%] h-[46px] w-[46px] rounded-full p-2  flex justify-center items-center border-[1px] border-[#1E1E1E] bg-[#0F0F0F]"
          >
            <div className="relative flex h-[15.95px] w-[15.95px] items-center justify-center md:h-[32px] md:w-[32px] bg-[#1B1B1B] p-2 rounded-full">
              <RefreshCcw size={24} />
            </div>
          </button>

          <div className="flex w-full flex-col">
            <div className="rounded-[24px] px-[10px] py-[10px] md:px-[24px] md:py-[20px] border border-[#1E1E1E] bg-[#1B1B1B]">
              <h3 className="mb-2 text-[9.97px] md:text-[16px] text-left text-[#F7F7F7] text-base">
                To
              </h3>
              <div className="flex justify-between">
                <div className="flex flex-col items-start">
                  <input
                    type="text"
                    value={parseFloat(equivalent).toFixed(3)}
                    placeholder="0"
                    readOnly
                    className="w-[45%] bg-transparent text-[18.59px] font-[700] outline-none md:w-[75%] md:text-[32px]"
                  />
                  <p className="ml-[2px] max-w-[45%] overflow-hidden text-ellipsis whitespace-nowrap text-[9.97px] font-[600] text-[#7A7A7A] md:text-[16px]">
                    = ${Number(equivalent).toFixed(3)}
                  </p>
                </div>
                <CustomSelect
                  selectedToken={toToken}
                  onTokenSelect={setToToken}
                />
              </div>
            </div>
          </div>
        </div>

        <div className="flex justify-between items-cente mt-6 text-sm leading-5 text-[#A4A4A4] mb-6">
          <h3>Gas fee: $0.00</h3>
          <h3>Gas fee: $0.00</h3>
        </div>

        {error && (
          <p className="mb-2 text-[9.97px] text-red-500 md:text-[16px]">
            {error}
          </p>
        )}

        <button
          onClick={handleSwap}
          disabled={isLoading || !address}
          type="submit"
          className={`w-full rounded-full py-[20px] font-[600] md:text-[16px] bg-[#2A2A2A] text-[#F4F4F4] ${
            isLoading ? "cursor-not-allowed opacity-50" : "cursor-pointer"
          }`}
        >
          {isLoading
            ? "Processing..."
            : address
            ? "Auto-Swap"
            : "Connect Wallet"}
        </button>
      </form>
    </div>
  );
};

export default Swapper;
