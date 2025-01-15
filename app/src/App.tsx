import React, { lazy, Suspense } from "react";
import { BrowserRouter as Router, Routes, Route } from "react-router-dom";
import { Providers } from "./provider";
import { HeaderBar } from "./components/headerBar";
import MicroLendingPage from "./pages/lending";
import MicroLendingCirclePage from "./pages/lending/[address]";
import Home from "./pages";
import "./globals.css";
import "./App.css";
import InsurancePage from "./pages/insurance";
import InsurancePoolPage from "./pages/insurance/[address]";

type RouteObject = {
  path: string;
  element: React.LazyExoticComponent<React.ComponentType<any>>;
  children?: RouteObject[];
};

// const importComponent = (path: string) => lazy(() => import(`./${path}`));

// const createRoutes = (): RouteObject[] => {
//   const modules = import.meta.glob("./pages/**/*.{js,jsx,ts,tsx}");
//   const routes: RouteObject[] = [];

//   for (const path in modules) {
//     const routePath = path
//       .replace("./pages", "")
//       .replace(/\.(js|jsx|ts|tsx)$/, "")
//       .replace(/\[(.+?)\]/g, ":$1")
//       .split("/")
//       .filter(Boolean);

//     let currentLevel = routes;

//     routePath.forEach((segment, index) => {
//       const isLast = index === routePath.length - 1;
//       const existingRoute = currentLevel.find((r) => r.path === segment);

//       segment = segment === "index" ? "" : segment;
//       if (existingRoute && !isLast) {
//         currentLevel = existingRoute.children = existingRoute.children || [];
//       } else if (!existingRoute) {
//         const newRoute: RouteObject = {
//           path: segment,
//           element: importComponent(path),
//         };
//         if (!isLast) {
//           newRoute.children = [];
//           currentLevel.push(newRoute);
//           currentLevel = newRoute.children;
//         } else {
//           currentLevel.push(newRoute);
//         }
//       }
//     });
//   }

//   return routes;
// };

// const RouteComponent: React.FC<{ routes: RouteObject[] }> = ({ routes }) => {
//   const renderRoutes = (routeList: RouteObject[], parentPath = "") => {
//     return routeList.map((route) => (
//       <Route
//         key={parentPath + route.path}
//         path={parentPath + route.path}
//         element={
//           <Suspense fallback={<div>Loading...</div>}>
//             <route.element />
//           </Suspense>
//         }
//       >
//         {route.children &&
//           renderRoutes(route.children, parentPath + route.path + "/")}
//       </Route>
//     ));
//   };

//   return <Routes>{renderRoutes(routes)}</Routes>;
// };

const App: React.FC = () => {
  // const routes = createRoutes();

  return (
    <div className="h-screen w-screen m-0 p-0 bg-gray-900">
      <Providers>
        <Router>
          <HeaderBar />
          {/* <RouteComponent routes={routes} /> */}
          <Routes>
            <Route
              path=""
              element={
                <Suspense fallback={<div>Loading...</div>}>
                  <Home />
                </Suspense>
              }
            />
            <Route
              path="lending"
              element={
                <Suspense fallback={<div>Loading...</div>}>
                  <MicroLendingPage />
                </Suspense>
              }
            />
            <Route
              path="lending/:address"
              element={
                <Suspense fallback={<div>Loading...</div>}>
                  <MicroLendingCirclePage />
                </Suspense>
              }
            />
            <Route
              path="insurance"
              element={
                <Suspense fallback={<div>Loading...</div>}>
                  <InsurancePage />
                </Suspense>
              }
            />
            <Route
              path="insurance/:address"
              element={
                <Suspense fallback={<div>Loading...</div>}>
                  <InsurancePoolPage />
                </Suspense>
              }
            />
          </Routes>
        </Router>
      </Providers>
    </div>
  );
};

export default App;
