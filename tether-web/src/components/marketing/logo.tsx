export function LogoMark({ size = 28 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 32 32" aria-hidden="true">
      <path
        d="M4 5h13a7 7 0 0 1 0 14h-2"
        fill="none"
        stroke="currentColor"
        strokeWidth="4.2"
        strokeLinecap="round"
      />
      <path
        d="M28 5H17M22 5v8a9 9 0 0 1-9 9 6 6 0 0 0 6 6h3"
        fill="none"
        stroke="#2de2c5"
        strokeWidth="4.2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

export function Logo() {
  return (
    <span className="mk-nav-logo">
      <LogoMark />
      TETHER
    </span>
  );
}
