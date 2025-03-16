import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Config } from "../Config";

export default function Hello() {
    const [message, setMessage] = useState<string>("Loading...");
    const navigate = useNavigate();

    useEffect(() => {
        fetch(`${Config.BASE_URL}/api/user/hello`, { credentials: "include" })
            .then(res => {
                if (res.redirected) {
                    window.location.href = res.url;
                } else if (res.status === 401) {
                    navigate("/not-authorized");
                } else {
                    return res.text();
                }
            })
            .then((data) => setMessage(data ?? "Unknown response"))
            .catch(() => setMessage("Not authenticated"));
    }, []);

    return <h1>{message}</h1>;
}