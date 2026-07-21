import type {NextConfig} from "next";

const nextConfig: NextConfig = {
  reactStrictMode: true,
  // Static export → a plain ./out folder, deployable as a free Render Static
  // Site (no server, no cold starts). The admin is a pure client-side Firebase
  // app — no API routes, server actions, or server-only imports — so nothing is
  // lost by exporting. Do NOT add trailingSlash: it would make usePathname
  // return "/reports/" and break the active-nav check in Shell.tsx.
  output: "export",
};

export default nextConfig;
