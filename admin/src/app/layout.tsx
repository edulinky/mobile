import type {Metadata} from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "EduLinky Admin",
  description: "Moderation and verification",
};

export default function RootLayout({children}: {children: React.ReactNode}) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
