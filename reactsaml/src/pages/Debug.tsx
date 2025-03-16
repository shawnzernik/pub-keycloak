import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Config } from "../Config";

interface DebugInfo {
    User?: string;
    SessionData?: string[];
}

export default function Debug() {
    const [debugInfo, setDebugInfo] = useState<DebugInfo | null>(null);
    const navigate = useNavigate();

    useEffect(() => {
        fetch(`${Config.BASE_URL}/api/debug`, { credentials: "include" })
            .then(res => {
                if (res.redirected) {
                    window.location.href = res.url;
                } else if (res.status === 401) {
                    navigate("/not-authorized");
                } else {
                    return res.json();
                }
            })
            .then((data: DebugInfo) => setDebugInfo(data))
            .catch(() => setDebugInfo(null));
    }, []);

    return (
        <div>
            <h1>Debug Information</h1>
            <pre>{JSON.stringify(debugInfo, null, 2)}</pre>
        </div>
    );
}