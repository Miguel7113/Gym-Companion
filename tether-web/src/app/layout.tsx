import './globals.css';
import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Tether',
  description: 'Gym operations, member engagement, and workout tracking for modern fitness teams.',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
