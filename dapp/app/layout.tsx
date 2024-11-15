import type { Metadata } from "next";
import "./globals.css";
import Navbar from "./components/navbar";
import { Providers } from "./components/providers";

export const metadata: Metadata = {
  title: "Create Next App",
  description: "Generated by create next app",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <Providers>
        <body className="relative bg-main-bg pt-[120px]">
          <Navbar />
          {children}
        </body>
      </Providers>
    </html>
  );
}
