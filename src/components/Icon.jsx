// Lightweight inline icon set (stroke-based, 24x24). No external dependency.
const P = { fill: 'none', stroke: 'currentColor', strokeWidth: 1.8, strokeLinecap: 'round', strokeLinejoin: 'round' }

const paths = {
  dashboard: <><rect x="3" y="3" width="7" height="9" rx="1.5" /><rect x="14" y="3" width="7" height="5" rx="1.5" /><rect x="14" y="12" width="7" height="9" rx="1.5" /><rect x="3" y="16" width="7" height="5" rx="1.5" /></>,
  brands: <><path d="M3 7l2-3h14l2 3" /><path d="M5 7v12a1 1 0 0 0 1 1h12a1 1 0 0 0 1-1V7" /><path d="M9 11h6" /></>,
  products: <><path d="M21 16V8a2 2 0 0 0-1-1.7l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.7l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" /><path d="M3.3 7L12 12l8.7-5M12 22V12" /></>,
  purchase: <><circle cx="9" cy="20" r="1.4" /><circle cx="18" cy="20" r="1.4" /><path d="M2 3h2.2l2.3 12.4a1.5 1.5 0 0 0 1.5 1.2h8.7a1.5 1.5 0 0 0 1.5-1.2L21 7H6" /></>,
  inventory: <><path d="M3 9l9-5 9 5v9l-9 5-9-5z" /><path d="M3 9l9 5 9-5M12 14v9" /><path d="M7.5 6.5l9 5" /></>,
  production: <><path d="M3 21h18M5 21V9l5 3V9l5 3V5l4 2v14" /></>,
  sales: <><path d="M3 3v18h18" /><path d="M7 14l3-4 3 3 5-7" /></>,
  billing: <><path d="M6 2h9l5 5v13a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1z" /><path d="M14 2v5h5" /><path d="M9 13h6M9 17h6M9 9h2" /></>,
  customers: <><circle cx="9" cy="8" r="3.2" /><path d="M3 20a6 6 0 0 1 12 0" /><path d="M16 5.5a3 3 0 0 1 0 5.4M21 20a5.5 5.5 0 0 0-3.5-5" /></>,
  suppliers: <><path d="M10 17h4V5H2v12h2" /><path d="M14 9h4l3 3v5h-3" /><circle cx="7.5" cy="17.5" r="1.6" /><circle cx="17.5" cy="17.5" r="1.6" /></>,
  logistics: <><rect x="1" y="6" width="13" height="10" rx="1" /><path d="M14 9h4l3 3v4h-7" /><circle cx="6" cy="18" r="1.6" /><circle cx="17" cy="18" r="1.6" /></>,
  reports: <><path d="M5 3h9l5 5v13H5z" /><path d="M14 3v5h5" /><path d="M9 13v4M12 11v6M15 15v2" /></>,
  settings: <><circle cx="12" cy="12" r="3" /><path d="M19.4 15a1.6 1.6 0 0 0 .3 1.8l.1.1a2 2 0 1 1-2.8 2.8l-.1-.1a1.6 1.6 0 0 0-2.7 1.1V21a2 2 0 1 1-4 0v-.1A1.6 1.6 0 0 0 7 19.4l-.1.1a2 2 0 1 1-2.8-2.8l.1-.1A1.6 1.6 0 0 0 3 12.6H3a2 2 0 1 1 0-4h.1A1.6 1.6 0 0 0 4.6 6l-.1-.1a2 2 0 1 1 2.8-2.8l.1.1A1.6 1.6 0 0 0 10 3V3a2 2 0 1 1 4 0v.1a1.6 1.6 0 0 0 2.7 1.1l.1-.1a2 2 0 1 1 2.8 2.8l-.1.1a1.6 1.6 0 0 0 1.1 2.7H21a2 2 0 1 1 0 4h-.1a1.6 1.6 0 0 0-1.5 1z" /></>,
  search: <><circle cx="11" cy="11" r="7" /><path d="m21 21-4.3-4.3" /></>,
  bell: <><path d="M18 8a6 6 0 1 0-12 0c0 7-3 9-3 9h18s-3-2-3-9" /><path d="M13.7 21a2 2 0 0 1-3.4 0" /></>,
  plus: <><path d="M12 5v14M5 12h14" /></>,
  edit: <><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" /><path d="M18.5 2.5a2.1 2.1 0 0 1 3 3L12 15l-4 1 1-4z" /></>,
  trash: <><path d="M3 6h18M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2M19 6l-1 14a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1L5 6" /></>,
  download: <><path d="M12 3v12M7 10l5 5 5-5M5 21h14" /></>,
  filter: <><path d="M3 4h18l-7 8v6l-4 2v-8z" /></>,
  menu: <><path d="M3 6h18M3 12h18M3 18h18" /></>,
  logout: <><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" /><path d="M16 17l5-5-5-5M21 12H9" /></>,
  alert: <><path d="M10.3 3.6 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.6a2 2 0 0 0-3.4 0z" /><path d="M12 9v4M12 17h0" /></>,
  rupee: <><path d="M6 3h12M6 8h12M9 13c5 0 5-5 0-5" /><path d="M6 13h3l6 8" /></>,
  box: <><path d="M3 9l9-5 9 5v9l-9 5-9-5z" /><path d="M3 9l9 5 9-5" /></>,
  truck: <><rect x="1" y="6" width="13" height="10" rx="1" /><path d="M14 9h4l3 3v4h-7" /><circle cx="6" cy="18" r="1.6" /><circle cx="17" cy="18" r="1.6" /></>,
  factory: <><path d="M3 21h18M5 21V9l5 3V9l5 3V5l4 2v14" /></>,
  check: <><path d="M20 6 9 17l-5-5" /></>,
  clock: <><circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" /></>,
  arrowUp: <><path d="M12 19V5M5 12l7-7 7 7" /></>,
  arrowDown: <><path d="M12 5v14M19 12l-7 7-7-7" /></>,
  close: <><path d="M18 6 6 18M6 6l12 12" /></>,
  user: <><circle cx="12" cy="8" r="4" /><path d="M4 21a8 8 0 0 1 16 0" /></>,
  cart: <><circle cx="9" cy="20" r="1.4" /><circle cx="18" cy="20" r="1.4" /><path d="M2 3h2.2l2.3 12.4a1.5 1.5 0 0 0 1.5 1.2h8.7a1.5 1.5 0 0 0 1.5-1.2L21 7H6" /></>,
  doc: <><path d="M6 2h9l5 5v13a1 1 0 0 1-1 1H6a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1z" /><path d="M14 2v5h5" /></>,
  layers: <><path d="M12 2 2 7l10 5 10-5z" /><path d="M2 12l10 5 10-5M2 17l10 5 10-5" /></>,
}

export default function Icon({ name, size = 18, className = '', style }) {
  const body = paths[name] || paths.box
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" className={className} style={style} {...P}>
      {body}
    </svg>
  )
}
