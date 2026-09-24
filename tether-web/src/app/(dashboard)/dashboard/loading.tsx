export default function DashboardLoading() {
  return (
    <div className="flex flex-col gap-4" aria-busy="true" aria-label="Loading dashboard">
      <div className="skeleton" style={{ height: 32, width: 220 }} />
      <div className="tdash-grid-kpi">
        {Array.from({ length: 4 }, (_, i) => (
          <div key={i} className="skeleton" style={{ height: 112 }} />
        ))}
      </div>
      <div className="tdash-grid-wide">
        <div className="skeleton" style={{ height: 300 }} />
        <div className="skeleton" style={{ height: 300 }} />
      </div>
    </div>
  );
}
