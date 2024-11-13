import React, { useEffect } from "react";
import ReactPortal from "./react-portal";

interface ModalProps {
  children: React.ReactNode;
  isOpen: boolean;
  handleClose: () => void;
}

export function Modal({ children, isOpen, handleClose }: ModalProps) {
  useEffect(() => {
    const closeOnEscapeKey = (e: KeyboardEvent) =>
      e.key === "Escape" ? handleClose() : null;
    document.body.addEventListener("keydown", closeOnEscapeKey);
    return (): void => {
      document.body.removeEventListener("keydown", closeOnEscapeKey);
    };
  }, [handleClose]);

  useEffect(() => {
    document.body.style.overflow = "hidden";
    return (): void => {
      document.body.style.overflow = "unset";
    };
  }, [isOpen]);

  if (!isOpen) {
    return null;
  }

  return (
    <ReactPortal containerId="react-portal-modal-container">
      <>
        <div
          className={`fixed top-0 left-0 w-screen h-screen z-40 bg-neutral-800 opacity-50`}
          onClick={handleClose}
        />
        <div
          onClick={handleClose}
          className={`fixed inset-0 flex flex-col box-border items-center justify-center
            z-40 p-0 overflow-hidden transition-all duration-300 ease-in-out
            `}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            className="border border-[#1E1E1E] rounded-3xl bg-[#0F0F0F]"
          >
            {children}
          </div>
        </div>
      </>
    </ReactPortal>
  );
}
