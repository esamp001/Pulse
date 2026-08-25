# 🚀 VPS Deployment & Cloudflare Tunnel Guide (Pulse / Rally 24/7 Backend)

This guide provides the complete, step-by-step documentation for deploying the **Pulse Backend** on a **100% Free 24/7 Oracle Cloud VPS** and exposing it securely via **Cloudflare Tunnel (HTTPS)** with zero open firewall ports and zero laptop dependency.

---

## 🏗️ Architecture Overview

```mermaid
graph TD
    subgraph Mobile Clients & CI/CD
        M[Flutter Mobile App / TestFlight / Play Store] -->|Secure HTTPS / WSS| CF[Cloudflare Global Edge]
        CI[Codemagic CI/CD] -->|API Health Checks| CF
    end

    subgraph Oracle Cloud Always Free VPS (24/7 Datacenter)
        CF -->|Encrypted Outbound Tunnel| CFT[cloudflared daemon (PM2)]
        CFT -->|Localhost Reverse Proxy| BE[Node.js / Express API (Port 5000 / PM2)]
        BE -->|Local Socket / Knex| DB[(PostgreSQL Database - pulse_db)]
    end
```

| Component | Technology | Cost | Uptime |
| :--- | :--- | :---: | :---: |
| **Compute Server** | Oracle Cloud Always Free (Linux VPS) | **$0.00** | 24/7/365 (Laptop can be OFF) |
| **Database** | PostgreSQL Server (`pulse_db`) | **$0.00** | 24/7/365 (Local to VPS) |
| **Process Daemon** | PM2 Runtime Manager | **$0.00** | Auto-boots on server restart |
| **Public HTTPS / SSL**| Cloudflare Tunnel (`cloudflared`) | **$0.00** | Unlimited bandwidth & users |

---

## 📍 Phase 1: Oracle Cloud Compute & VCN Setup

### 1. Create Virtual Cloud Network (VCN)
1. Go to **Networking** ➡️ **Virtual Cloud Networks**.
2. Click **Start VCN Wizard** ➡️ select **Create VCN with Internet Connectivity** (or create manual VCN `rally-vcn`).
3. Ensure the VCN has an **Internet Gateway** (`rally-igw`) and the **Default Route Table** has a rule:
   - **Target Type**: `Internet Gateway`
   - **Destination CIDR**: `0.0.0.0/0`
   - **Target**: `rally-igw`

### 2. Create Compute Instance
1. Go to **Compute** ➡️ **Instances** ➡️ **Create instance**.
2. **Name**: `instance-20260824-2201` (or `rally-server`).
3. **Image**: Canonical Ubuntu or Oracle Linux 9.
4. **Shape**: `VM.Standard.E2.1.Micro` (AMD) or `VM.Standard.A1.Flex` (Ampere ARM) *(Always Free Eligible)*.
5. **Networking**: Select `rally-vcn` and `rally-public-subnet`. Ensure **"Assign Public IPv4 Address"** is set to **Yes**.
6. **SSH Keys**: Choose **"Generate a key pair for me"** and click **"Download private key"** (`ssh-key-2026-08-24.key`).
7. Click **Create**. Copy the **Public IP Address** (e.g. `161.118.212.40`).

---

## 🔑 Phase 2: Connecting via SSH (Windows PowerShell)

1. Open **PowerShell** on your local machine and navigate to where the `.key` file is stored:
   ```powershell
   cd C:\Users\<YOUR_USER>\Downloads
   ```

2. Lock down private key file permissions (Windows OpenSSH requirement):
   ```powershell
   icacls .\ssh-key-2026-08-24.key /inheritance:r
   icacls .\ssh-key-2026-08-24.key /grant:r "$($env:USERNAME):(R)"
   ```

3. Connect to the cloud server:
   ```powershell
   # For Oracle Linux:
   ssh -i .\ssh-key-2026-08-24.key opc@161.118.212.40

   # For Ubuntu Linux:
   ssh -i .\ssh-key-2026-08-24.key ubuntu@161.118.212.40
   ```

---

## ⚙️ Phase 3: Server Optimization (2GB Virtual RAM Swap)

On 1GB RAM instances, compile tools (`dnf`, `npm install`, TypeScript builds) require swap space to prevent Out-Of-Memory (OOM) kills.

Run this inside the Linux server:
```bash
sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

---

## 📦 Phase 4: Installing Runtimes & PostgreSQL Database

### 1. Install Node.js 20 LTS, Build Tools & PM2
```bash
# Install Node.js 20 repository & packages
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo dnf install -y nodejs gcc-c++ make git

# Install PM2 Process Manager globally
sudo npm install -g pm2
```

### 2. Install & Configure PostgreSQL
```bash
# 1. Install PostgreSQL server
sudo dnf install -y postgresql-server postgresql-contrib

# 2. Initialize database cluster
sudo postgresql-setup --initdb

# 3. Allow password login for localhost connections
sudo sed -i 's/ident/md5/g' /var/lib/pgsql/data/pg_hba.conf

# 4. Start PostgreSQL and enable it 24/7 on boot
sudo systemctl enable --now postgresql
```

### 3. Create Database & User
```bash
sudo -u postgres psql -c "CREATE DATABASE pulse_db;"
sudo -u postgres psql -c "CREATE USER pulse_user WITH ENCRYPTED PASSWORD 'pulse_secure_password_2026';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE pulse_db TO pulse_user;"
sudo -u postgres psql -d pulse_db -c "GRANT ALL ON SCHEMA public TO pulse_user;"
```

---

## 🚀 Phase 5: Deploying Backend Code & Starting Services

### 1. Navigate to Backend Directory
```bash
cd ~/backend
npm install
```

### 2. Configure `.env`
Create or edit `.env`:
```bash
nano .env
```
Paste configuration:
```env
PORT=5000
NODE_ENV=production
DB_HOST=localhost
DB_PORT=5432
DB_USER=pulse_user
DB_PASSWORD=pulse_secure_password_2026
DB_NAME=pulse_db
JWT_SECRET=pulse_jwt_super_secret_production_key_2026
JWT_EXPIRES_IN=7d
```
*(Save with `Ctrl + O`, `Enter`, exit with `Ctrl + X`).*

### 3. Rebuild Native Modules & Run Migrations
```bash
# 1. Grant execution rights to node binaries
chmod -R +x node_modules/.bin

# 2. Rebuild bcrypt for Linux
npm rebuild bcrypt --build-from-source

# 3. Run database migrations
npm run migrate:latest

# 4. Compile TypeScript to JavaScript
npm run build
```

### 4. Start Backend Daemon 24/7 with PM2
```bash
pm2 start dist/server.js --name "pulse-backend"
pm2 save
pm2 startup
```

---

## 🌐 Phase 6: Exposing Backend via Cloudflare Tunnel (HTTPS)

### 1. Install `cloudflared` on Linux
```bash
sudo dnf install -y https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-x86_64.rpm
```

### 2. Launch Tunnel 24/7

#### Option A: Instant Quick Tunnel (No Domain Needed)
Run inside PM2 so it stays alive 24/7 even when your laptop is off:
```bash
pm2 start "cloudflared tunnel --url http://localhost:5000" --name "pulse-tunnel"
pm2 save
```

To view your generated live URL:
```bash
pm2 logs pulse-tunnel --lines 30
# Example URL: https://retailers-nuke-unsigned-jaguar.trycloudflare.com
```

#### Option B: Named Tunnel with Custom Domain (Zero Trust)
1. In [Cloudflare Zero Trust Dashboard](https://dash.cloudflare.com/) ➡️ **Networks** ➡️ **Tunnels** ➡️ **Create Tunnel** (`pulse-oracle`).
2. Run the provided command on your server:
   ```bash
   sudo cloudflared service install <YOUR_SECRET_TOKEN>
   ```
3. Under **Public Hostname**, map `api.yourdomain.com` ➡️ `HTTP` ➡️ `localhost:5000`.

---

## 📱 Phase 7: Mobile App & CI/CD Integration

Update your Flutter mobile environment to point to the live 24/7 HTTPS URL:

### 1. In `mobile/.env`:
```env
API_BASE_URL=https://retailers-nuke-unsigned-jaguar.trycloudflare.com/api/v1
```

### 2. In `codemagic.yaml`:
```yaml
    environment:
      flutter: stable
      vars:
        API_BASE_URL: "https://retailers-nuke-unsigned-jaguar.trycloudflare.com/api/v1"
```

---

## 🛠️ Maintenance & Useful Commands Cheat Sheet

| Task | Command |
| :--- | :--- |
| **SSH into Server** | `ssh -i .\ssh-key-2026-08-24.key opc@161.118.212.40` |
| **Check Process Status** | `pm2 status` |
| **View Backend Logs** | `pm2 logs pulse-backend` |
| **View Tunnel Logs / URL** | `pm2 logs pulse-tunnel` |
| **Restart Backend** | `pm2 restart pulse-backend` |
| **Restart All Services** | `pm2 restart all` |
| **Update Backend Code** | `cd ~/backend && git pull && npm run build && pm2 restart pulse-backend` |
| **Check RAM & System Load** | `free -h` or `htop` |

---

## 📖 Key Terminology Glossary

* **"SSH into the Server"**: Connecting remotely to your cloud Linux computer from PowerShell using `ssh -i ...` (Secure Shell).
* **"Spinning Up / Provisioning"**: Creating a virtual server in Oracle Cloud.
* **"Daemon / Service"**: A background program (managed by PM2) that runs 24/7 even when your terminal window is closed.
* **"Cloudflare Tunnel"**: The secure bridge that routes public internet traffic to your server without opening firewall ports.

