"use client";

import { useLayoutEffect, useState } from "react";
import { createPortal } from "react-dom";

interface ReactPortalProps {
  children: React.ReactElement;
  containerId: string;
}

const createContainerAndAppendToBody = (containerId: string) => {
  if (!document) return null;
  const wrapperElement = document.createElement("div");
  wrapperElement.setAttribute("id", containerId);
  document.body.appendChild(wrapperElement);
  return wrapperElement;
};

export default function ReactPortal({
  children,
  containerId,
}: ReactPortalProps) {
  const [containerElement, setContainerElement] = useState<HTMLElement>();

  useLayoutEffect(() => {
    let container = document.getElementById(containerId);
    let systemCreated = false;
    if (!container) {
      systemCreated = true;
      container = createContainerAndAppendToBody(containerId);
    }
    setContainerElement(container!);
  }, [containerId]);

  if (containerElement == null) {
    return null;
  }
  return createPortal(children, containerElement);
}
