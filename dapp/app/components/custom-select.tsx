"use client";

import { ChevronDown, ChevronUp } from "lucide-react";
import { Modal } from "./modal";
import { SwapFrom, SwapTo } from "./swap-modals";
import { Token, tokenAddresses, tokenImages } from "@/constants/tokens";
import { useState } from "react";

export const CustomSelect: React.FC<{
  selectedToken: Token;
  onTokenSelect: (token: Token) => void;
  setAmount?: (amount: string) => void;
  from: boolean;
}> = ({ selectedToken, onTokenSelect, setAmount, from }) => {
  const [isOpen, setIsOpen] = useState(false);
  const tokens = Object.keys(tokenAddresses) as Array<Token>;

  const handleSelect = (token: string) => {
    onTokenSelect(token as Token);
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
        <>
          {/* <div className="absolute left-0 top-12 z-10 w-full rounded-md bg-[#131313] border-[1px] border-[#1E1E1E] text-[8.97px] text-[#f7f7f7] shadow-lg md:text-[16px]">
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
          </div> */}
          <Modal isOpen={isOpen} handleClose={() => setIsOpen(!isOpen)}>
            {from ? (
              <SwapFrom
                handleClose={() => setIsOpen(!isOpen)}
                onTokenSelect={onTokenSelect}
                from
              />
            ) : (
              <SwapTo
                handleClose={() => setIsOpen(!isOpen)}
                onTokenSelect={onTokenSelect}
                setAmount={setAmount}
                from={false}
              />
            )}
          </Modal>
        </>
      )}
    </div>
  );
};
