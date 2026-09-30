export function Marquee({ items }: { items: string[] }) {
  const track = (hidden?: boolean) => (
    <div className="mk-marquee-track" aria-hidden={hidden || undefined}>
      {items.map((item) => (
        <span key={item} className="mk-marquee-item">
          {item}
        </span>
      ))}
    </div>
  );

  return (
    <div className="mk-marquee">
      {track()}
      {track(true)}
    </div>
  );
}
