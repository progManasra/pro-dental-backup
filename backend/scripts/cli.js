#!/usr/bin/env node
const { Command } = require("commander");
const fs = require("fs");
const path = require("path");

const BASE_URL = "http://localhost:8091/api/v1";
const TOKEN_FILE = path.join(__dirname, ".pd-token");

function getToken() {
  if (!fs.existsSync(TOKEN_FILE)) return null;
  return fs.readFileSync(TOKEN_FILE, "utf8").trim();
}

function saveToken(token) {
  fs.writeFileSync(TOKEN_FILE, token, "utf8");
}

async function api(method, url, body) {
  const token = getToken();
  if (!token) {
    console.log("❌ Not logged in. Run: pd login --token YOUR_TOKEN");
    process.exit(1);
  }

  const res = await fetch(`${BASE_URL}${url}`, {
    method,
    headers: {
      "Content-Type": "application/json",
      "Authorization": `Bearer ${token}`
    },
    body: body ? JSON.stringify(body) : undefined
  });

  const data = await res.json().catch(() => ({}));
  if (!res.ok) {
    console.log("❌ Error:", data.message || data.error || res.statusText);
    process.exit(1);
  }
  console.log(JSON.stringify(data, null, 2));
}

const program = new Command();

program
  .name("pd")
  .description("ProDental CLI")
  .version("1.0.0");


// 🔐 Login
program
  .command("login")
  .requiredOption("--token <jwt>", "JWT Token")
  .action(({ token }) => {
    saveToken(token);
    console.log("✅ Token saved.");
  });


// 👤 USERS
program.command("users:list").action(() => api("GET", "/users"));
program.command("users:delete").requiredOption("--id <id>").action(o => api("DELETE", `/users/${o.id}`));
program.command("users:doctors").action(() => api("GET", "/users/by-role/DOCTOR"));


// 📅 SCHEDULES
program.command("sched:weekly").action(() => api("GET", "/schedules/weekly"));
program.command("sched:board").requiredOption("--date <YYYY-MM-DD>").action(o => api("GET", `/schedules/board?date=${o.date}`));


// 📆 APPOINTMENTS
program.command("appts:me").action(() => api("GET", "/appointments/me"));
program.command("appts:done").requiredOption("--id <id>").action(o =>
  api("POST", `/appointments/${o.id}/doctor-action`, { status: "COMPLETED" })
);


// 🛠 DEV
program.command("health").action(() => api("GET", "/users"));

program.parse(process.argv);
