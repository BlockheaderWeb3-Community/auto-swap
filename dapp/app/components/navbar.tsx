import ConnectWallet from "./connect-wallet";

export default function Navbar() {
  return (
    <nav className="flex justify-between absolute top-0 left-0 w-full bg-[#0F0F0F] bg-opacity-80 backdrop-blur-lg py-7 px-[80px]">
      <div>Swappr</div>
      <div className="flex items-center gap-x-3">
        <div className="flex items-center gap-x-2">
          <h3 className="text-[#7C7C7C] text-sm">Current timezone</h3>
          <h4 className="flex items-center gap-x-2 text-base text-[#F9F9F9]">
            3:00 PM UTC <img src="/globe-icon.svg" alt="" />
          </h4>
        </div>
        <ConnectWallet />
      </div>
    </nav>
  );
}
