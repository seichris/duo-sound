import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Hingy App Store Screenshots",
  description: "Local App Store asset renderer for Hingy.",
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
