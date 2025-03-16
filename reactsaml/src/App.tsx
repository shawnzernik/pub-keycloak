import { useEffect, useState } from "react";
import { useNavigate, Link } from "react-router-dom";
import { Config } from "./Config"; // Import Config class

export default function App() {
    const [user, setUser] = useState<string | null>(null);
    const navigate = useNavigate();

    useEffect(() => {
        fetch(`${Config.BASE_URL}/api/auth/status`, { credentials: "include" })  // ✅ Correct Syntax
            .then(res => res.ok ? res.json() : Promise.reject())
            .then((data: { username: string }) => setUser(data.username))
            .catch(() => navigate("/not-authorized"));
    }, []);

    if (!user) return <p>Loading...</p>;
    return (
        <>
            <h1>Welcome, {user}</h1>
            <nav>
                <ul>
                    <li><Link to="/debug">Debug</Link></li>
                    <li><Link to="/hello">Hello</Link></li>
                </ul>
            </nav>
        </>
    );

}