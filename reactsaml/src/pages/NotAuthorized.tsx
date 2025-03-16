import { Config } from "../Config";  // Import Config class for BASE_URL

export default function NotAuthorized() {
    return (
        <div>
            <h1>Not Authorized</h1>
            <p>You are not logged in. Please authenticate.</p>
            <a href={`${Config.BASE_URL}/api/auth/login`}>Login</a>
        </div>
    );
}