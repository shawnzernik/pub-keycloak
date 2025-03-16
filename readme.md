# Project Overview

NOTE: this application and repository was created with the assistance of ChatGPT.  The "context.sh" builds scripts you can run past ChatGPT 4o and build up a context to ask questions.

This project is a **SAML authentication system** integrating **Keycloak, .NET 8 Web API (`net8saml`), and a React frontend (`reactsaml`)**. It provides Single Sign-On (SSO) using **SAML 2.0** and supports **session management, user authentication, and secure communication** between components.

## **1. Architectural Overview**

### **Components**
- **Keycloak (Identity Provider - IdP)**: Manages authentication and issues **SAML assertions**.
- **.NET 8 Web API (`net8saml`)**: Handles **SAML authentication callbacks**, user sessions, and provides API endpoints.
- **React + Vite Frontend (`reactsaml`)**: Acts as the UI for users, interacting with the backend for authentication and data display.

### **Flow**
1. The **React frontend** redirects users to **Keycloak's SAML login page**.
2. **Keycloak authenticates users** and returns a **SAML assertion** to the .NET backend.
3. The **.NET API validates the assertion**, creates a session, and provides authenticated API access.
4. The **React frontend communicates** with the backend to retrieve user session data.

---

## **2. Keycloak: Build, Create, and Configure**

### **Step 1: Build the Keycloak Docker Image**
```bash
cd keycloak
bash build.sh
```
This builds the **Keycloak Docker image** and pushes it to the container registry.

### **Step 2: Create and Start the Keycloak Container**
```bash
bash create.sh
```
This starts a Keycloak container on **port 8080**.

### **Step 3: Configure Keycloak with SAML Client**
```bash
bash configure.sh
```
This script:
- Creates a new **realm** (`mycompany`).
- Registers a **SAML client** (`net8saml`).
- Configures SAML authentication settings.
- Creates a test **user (`shawnz`)** and **group (`net8saml_admins`)**.

---

## **3. Configure and Build .NET Web API (`net8saml`)**

### **Step 1: Set Up the .NET Environment**

Install .NET 8:

- https://dotnet.microsoft.com/en-us/download/dotnet/8.0

### **Step 2: Restore Dependencies and Build**
```bash
cd net8saml
dotnet restore
dotnet build
```
This compiles the **.NET Web API**.

### **Step 3: Configure SAML Authentication (`appsettings.json`)**
Ensure the **SAML settings** are correctly configured in `appsettings.json`:
```json
"SAML": {
  "IdpSsoUrl": "http://localhost:8080/realms/mycompany/protocol/saml",
  "EntityId": "net8saml",
  "AssertionConsumerServiceUrl": "http://localhost:5000/api/auth/callback",
  "PrivateKeyPath": "../private-key-pkcs8.pem"
}
```

---

## **4. Generate Certificates for SAML Authentication**
```bash
cd keycloak
bash certs.sh
```
This script:
- Extracts the **SAML signing certificate** and **private key** from Keycloak.
- Saves them as `private-key.pem` and `public-cert.pem`.
- Converts the private key to **PKCS8 format** (`private-key-pkcs8.pem`).

Ensure the **backend API** references these files in `appsettings.json`.

---

## **5. Build and Configure React Frontend (`reactsaml`)**

### **Step 1: Install Dependencies**
```bash
cd reactsaml
npm install
```

### **Step 2: Configure API Endpoint**
Edit `.env`:
```bash
echo "VITE_API_BASE_URL=http://localhost:5000" > reactsaml/.env
```

### **Step 3: Build the React App**
```bash
npm run build
```
This generates the **production build** in `reactsaml/dist`, which is served by the **.NET Web API**.

---

## **6. Run the .NET Web API and Frontend**

### **Step 1: Start the React Frontend (Development Mode)**
```bash
cd reactsaml
npm run dev
```
This runs the React app at **http://localhost:5000**, pointing to the backend API at **http://localhost:5000**.

### **Step 2: Start the .NET Web API**
```bash
cd net8saml
dotnet run
```
This starts the API at **http://localhost:5000**.

### **Step 3: Access the Application**
- **Keycloak Admin Console**: [http://localhost:8080](http://localhost:8080) (Username: `admin`, Password: `admin`)
- **React Frontend**: [http://localhost:500](http://localhost:500) (Username: `shawnz`, Password: `Shawn123`)
- **Backend API**: [http://localhost:5000/swagger](http://localhost:5000/swagger) (Swagger UI)

---

## **7. API Endpoints Overview**

| Endpoint                  | Method | Description |
|---------------------------|--------|-------------|
| `/api/auth/login`         | `GET`  | Redirects user to Keycloak SSO. |
| `/api/auth/callback`      | `POST` | Handles SAML authentication response. |
| `/api/debug`              | `GET`  | Returns session data for debugging. |
| `/api/user/hello`         | `GET`  | Returns "Hello {user}" message. |

---

## **Conclusion**
This project provides a **secure and scalable authentication solution using SAML with Keycloak, .NET 8, and React**. You can now deploy and extend it based on your authentication and authorization needs.

🚀 **Happy Coding!**
