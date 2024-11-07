import Swapper from "./components/swapper";

export default function Home() {
  return (
    <div className="flex flex-col items-center text-center pt-[70px]">
      <h1 className="max-w-[700px] text-[28px] font-semibold text-[#F7F7F7] mb-6">
        Activate auto-swap from unstable assets to a stable asset
      </h1>
      <Swapper />
    </div>
  );
}
