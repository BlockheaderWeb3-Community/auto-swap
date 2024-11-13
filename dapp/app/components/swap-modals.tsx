"use client";

import { RightBorder, TimePassed } from "@/assets/swap-modals";
import { Token, tokenAddresses, tokenImages } from "@/constants/tokens";
import { CircleCheck, PenLine, Search, X } from "lucide-react";
import { useState } from "react";

interface ModalProps {
  from: boolean;
  handleClose: () => void;
  onTokenSelect: (token: Token) => void;
  setAmount?: (amount: string) => void;
}

const ModalHeader = ({
  handleClose,
  from,
}: {
  handleClose: () => void;
  from: boolean;
}) => (
  <div className="flex items-center justify-between w-full">
    <div className="flex gap-[.5rem] items-center">
      <p className="text-[#7C7C7C] text-xs">Select a token</p>
      <RightBorder />
      <p className="text-base text-[#F9F9F9]">Swap {from ? "From" : "To"}</p>
    </div>
    <X onClick={handleClose} className="cursor-pointer" />
  </div>
);

const SearchToken = ({
  searchTokens,
}: {
  searchTokens: (e: Token) => void;
}) => (
  <div
    className={`flex w-full h-12 bg-[#141414] py-3 px-4 justify-between items-center
    rounded-[900px] focus-within:outline-1`}
  >
    <label htmlFor="search-from" className="sr-only"></label>
    <input
      type="search"
      id="search-from"
      placeholder="Search tokens..."
      onChange={(e) => searchTokens(e.target.value as Token)}
      className="grow-[2] border-none focus:outline-none bg-[#141414] text-base"
    />
    <Search />
  </div>
);

const RecentToken = ({
  onTokenSelect,
  handleClose,
}: {
  onTokenSelect: (token: Token) => void;
  handleClose: () => void;
}) => {
  return (
    <div>
      <div className="flex gap-1 items-center justify-start text-sm mb-4">
        <TimePassed />
        <span>Recent searches</span>
      </div>
      <TokenCard
        token={"STRK"}
        onTokenSelect={onTokenSelect}
        handleClose={handleClose}
      />
    </div>
  );
};

const Tokens = ({
  handleClose,
  onTokenSelect,
  tokens,
}: {
  handleClose: () => void;
  onTokenSelect: (token: Token) => void;
  tokens: Token[];
}) => {
  const [tobi, searchTobi] = useState(
    Object.keys(tokenAddresses) as Array<Token>,
  );
  const tokun = Object.keys(tokenAddresses) as Array<Token>;
  return (
    <div>
      <p className="mb-4">Tokens</p>
      <div className="flex flex-col items-center justify-start gap-5">
        {tokens.map((token) => (
          <TokenCard
            key={token}
            token={token}
            onTokenSelect={onTokenSelect}
            handleClose={handleClose}
          />
        ))}
      </div>
    </div>
  );
};

const TokenCard = ({
  token,
  onTokenSelect,
  handleClose,
}: {
  token: Token;
  onTokenSelect?: (token: Token) => void;
  handleClose: () => void;
}) => {
  const handleSelect = (token: string) => {
    onTokenSelect!(token as Token);
    return handleClose();
  };

  return (
    <button
      onClick={() => handleSelect(token)}
      className="self-start flex gap-2 text-base items-center justify-start"
    >
      <img src={tokenImages[token]} alt="" className="w-8 h-8" />
      <div className="text-start">
        <p>{token}</p>
        <p className="text-xs text-[#424242]">{token}</p>
      </div>
    </button>
  );
};

type PercentageLabel = "25%" | "50%" | "75%" | "100%";
const PercentFieldSet = ({
  setPercent,
  disabled,
}: {
  setPercent: (percent: PercentageLabel) => void;
  disabled: boolean;
}) => {
  return (
    <fieldset
      disabled={disabled}
      className={`${disabled ? "disabled:opacity-75" : ""}`}
    >
      <legend className="mb-4">
        Select the percentage you want to auto-swap
      </legend>
      <div className="flex gap-3">
        {[
          { label: "25%", id: "twenty-five" },
          { label: "50%", id: "fifty" },
          { label: "75%", id: "seventy-five" },
          { label: "100%", id: "hundred" },
        ].map(({ label, id }) => (
          <div key={id} className={`flex items-center`}>
            <input
              type="radio"
              id={id}
              name="radio-group"
              value={label}
              className={`hidden peer`}
              onClick={() => setPercent(label as PercentageLabel)}
            />
            <label
              htmlFor={id}
              className={`bg-[#141414] text-sm font-semibold uppercase w-[4.5rem]
                lg:w-24 h-10 text-center py-2 px-4 rounded-full shadow-sm
                peer-checked:bg-[#2BB2FF] peer-checked:text-white peer-checked:border-blue-500
                ${disabled ? "cursor-not-allowed" : "cursor-pointer"}`}
            >
              {label}
            </label>
          </div>
        ))}
      </div>
    </fieldset>
  );
};

type StableToken = "USDT" | "USDC" | "";
const TokenFieldSet = ({
  setTokenField,
}: {
  setTokenField: (token: StableToken) => void;
}) => {
  const stableTokens: StableToken[] = ["USDT", "USDC"];
  return (
    <div className="w-full">
      <div className="flex gap-1 items-center justify-start text-sm mb-4">
        <TimePassed />
        <span>Stable Tokens</span>
      </div>
      <fieldset className="w-full">
        <div className="flex justify-between w-full gap-5">
          {stableTokens.map((stable) => (
            <div key={stable} className="relative w-full">
              <input
                type="radio"
                id="usdt"
                className="appearance-none absolute inset-0 cursor-pointer peer"
                name="token-group"
                onClick={() => {
                  return setTokenField(stable);
                }}
              />
              <label
                className={`flex justify-between items-center border border-[#1E1E1E] text-[#1E1E1E]
          rounded-full w-full py-1 px-2 peer-checked:text-[#2BB2FF] peer-checked:border-[#2BB2FF]`}
              >
                <div className="self-start flex gap-2 text-base items-center justify-start">
                  <img
                    src={tokenImages[stable as Token]}
                    alt=""
                    className="w-8 h-8"
                  />
                  <div className="text-start text-[#F9F9F9]">
                    <p className="capitalize">{stable.toLowerCase()}</p>
                    <p className="text-xs text-[#424242]">{stable}</p>
                  </div>
                </div>
                <CircleCheck className="w-6 h-6" />
              </label>
            </div>
          ))}
        </div>
      </fieldset>
    </div>
  );
};

const AmountInput = ({
  setAmountField,
  disabled,
}: {
  setAmountField: (amount: string) => void;
  disabled: boolean;
}) => {
  const numberRegex = /^[0-9]*[.,]?[0-9]*$/;
  const handleAmountChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const value = e.target.value;
    console.log(value);
    if (numberRegex.test(value)) {
      setAmountField(value);
    }
  };
  return (
    <div
      className={`flex w-full h-12 bg-[#141414] py-3 px-4 justify-between items-center
  rounded-[900px] focus-within:outline-1 focus-within:bg-[#141414]`}
    >
      <label htmlFor="input-amount" className="sr-only">
        Amount
      </label>
      <input
        type="text"
        onChange={handleAmountChange}
        id="input-amount"
        name="input-amount"
        placeholder="Input how much you want to swap"
        disabled={disabled}
        className={`grow-[2] border-none focus:outline-none focus:text-[#F9F9F9]
          bg-[#141414] text-base focus:bg-[#141414]
          ${disabled ? "cursor-not-allowed" : "cursor-text"}`}
      />
      <PenLine />
    </div>
  );
};

/**
    Swap To Modal
    Returns
        To Token
        Amount | Percentage
*/
export function SwapTo({ handleClose, onTokenSelect, setAmount }: ModalProps) {
  const [amountField, setAmountField] = useState("");
  const [percentField, setPercent] = useState<PercentageLabel | "">("");
  const [tokenField, setTokenField] = useState<"USDT" | "USDC" | "">("");
  const [disabled, setDisabled] = useState(
    tokenField !== "" && (percentField !== "" || amountField !== ""),
  );

  const handleFields = () => {
    if (tokenField != "" && (percentField != "" || amountField != "")) {
      setDisabled(!disabled);
      onTokenSelect(tokenField);
      handleClose();
    }
  };

  return (
    <div
      className={`p-6 lg:p-12 flex flex-col gap-6 lg:gap-7 h-max-[40rem]
      w-[24rem] lg:w-[32rem] items-start no-scrollbar overflow-y-auto`}
    >
      <ModalHeader handleClose={handleClose} from={false} />
      <AmountInput
        setAmountField={setAmountField}
        disabled={percentField != ""}
      />
      <PercentFieldSet setPercent={setPercent} disabled={amountField != ""} />
      <hr className="h-[1px] border border-[#1E1E1E] w-full bg-[#1E1E1E] border-solid rounded" />
      <TokenFieldSet setTokenField={setTokenField} />
      <button
        disabled={disabled}
        onClick={handleFields}
        className={`w-full py-4 text-center rounded-full border-none font-semibold
          bg-[#2BB2FF] cursor-pointer`}
      >
        Done
      </button>
    </div>
  );
}

/**
    Swap From Modal
*/
export function SwapFrom({ handleClose, onTokenSelect, from }: ModalProps) {
  const [tokens, setTokens] = useState<Token[]>(
    Object.keys(tokenAddresses) as Array<Token>,
  );

  const searchTokens = (search: Token) => {
    const tokens = Object.keys(tokenAddresses) as Array<Token>;
    setTokens(tokens.filter((token) => token.toLowerCase().includes(search)));
  };

  return (
    <div
      className={`p-6 lg:p-12 flex flex-col gap-6 lg:gap-7 h-max-[40rem]
      w-[24rem] lg:w-[32rem] items-start no-scrollbar overflow-y-auto`}
    >
      <ModalHeader handleClose={handleClose} from />
      <SearchToken searchTokens={searchTokens} />
      <RecentToken onTokenSelect={onTokenSelect} handleClose={handleClose} />
      <hr className="h-[1px] border border-[#1E1E1E] w-full bg-[#1E1E1E] border-solid rounded" />
      <Tokens
        onTokenSelect={onTokenSelect}
        handleClose={handleClose}
        tokens={tokens}
      />
    </div>
  );
}
