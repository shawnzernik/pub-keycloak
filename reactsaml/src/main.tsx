import React from "react";
import ReactDOM from "react-dom/client";
import { BrowserRouter, Routes, Route } from "react-router-dom";
import App from "./App";
import NotAuthorized from "./pages/NotAuthorized";
import Debug from "./pages/Debug";
import Hello from "./pages/Hello";

ReactDOM.createRoot(document.getElementById("root") as HTMLElement).render(
    <BrowserRouter>
        <Routes>
            <Route path="/" element={<App />} />
            <Route path="/not-authorized" element={<NotAuthorized />} />
            <Route path="/debug" element={<Debug />} />
            <Route path="/hello" element={<Hello />} />
        </Routes>
    </BrowserRouter>
);