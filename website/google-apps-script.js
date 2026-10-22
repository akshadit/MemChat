/**
 * MemChat Beta Tester Google Apps Script Webhook
 * 
 * Instructions to deploy:
 * 1. Open Google Sheets (https://sheets.new)
 * 2. Rename the Sheet title to "MemChat Beta Testers"
 * 3. In the top menu, go to: Extensions > Apps Script
 * 4. Delete any code in the editor and paste this entire script
 * 5. Update ADMIN_EMAIL below with any email where you want alerts delivered!
 * 6. Click "Deploy" > "New deployment"
 * 7. Click the gear icon > Select "Web app"
 * 8. Set Description: "MemChat Webhook"
 * 9. Set "Execute as": "Me (your email)"
 * 10. Set "Who has access": "Anyone" (allows the website to POST registrations)
 * 11. Click "Deploy", authorize permissions, and copy the "Web app URL"
 * 12. Paste the Web app URL into `website/script.js` as GOOGLE_SHEET_WEBHOOK_URL
 */

// You can change this to ANY email address! 
// When deployed, Google sends the notification email through your Gmail account directly to this address.
const ADMIN_EMAIL = "akshayaditya1976@gmail.com"; 

const NOTIFY_VIA_EMAIL = true;

function doPost(e) {
  try {
    const lock = LockService.getScriptLock();
    lock.waitLock(10000); // 10s wait

    let data = {};
    if (e.postData && e.postData.contents) {
      try {
        data = JSON.parse(e.postData.contents);
      } catch (err) {
        data = e.parameter;
      }
    } else if (e.parameter) {
      data = e.parameter;
    }

    const name = data.name || "Anonymous";
    const email = (data.email || "").trim().toLowerCase();
    const device = data.device || "Android Device";
    const role = data.role || data.use_case || "Personal & Family Files";
    const timestamp = data.timestamp || new Date().toLocaleString("en-US", { timeZone: "Asia/Kolkata" });
    const status = "Pending Google Cloud";

    if (!email) {
      return ContentService.createTextOutput(JSON.stringify({
        success: false,
        error: "Missing email address"
      })).setMimeType(ContentService.MimeType.JSON);
    }

    const sheet = getOrCreateSheet();
    
    // Check if email already exists in column D (index 3)
    const values = sheet.getDataRange().getValues();
    let alreadyExists = false;
    for (let i = 1; i < values.length; i++) {
      if (values[i][3] && values[i][3].toString().toLowerCase() === email) {
        alreadyExists = true;
        break;
      }
    }

    if (!alreadyExists) {
      const nextId = values.length; // Row index as ID
      sheet.appendRow([nextId, timestamp, name, email, device, role, status]);

      // Send instant email notification
      if (NOTIFY_VIA_EMAIL && ADMIN_EMAIL) {
        sendNotificationEmail(name, email, device, role, timestamp);
      }
    }

    lock.releaseLock();

    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      alreadyExists: alreadyExists,
      message: alreadyExists ? "Tester already registered" : "Successfully added to Google Sheet & notified developer"
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function doGet(e) {
  try {
    const sheet = getOrCreateSheet();
    const rows = sheet.getDataRange().getValues();
    
    const testers = [];
    // Skip header row at index 0
    for (let i = 1; i < rows.length; i++) {
      const row = rows[i];
      if (row[3]) { // Email exists
        testers.push({
          id: row[0] ? row[0].toString() : (i).toString(),
          timestamp: row[1] || "",
          name: row[2] || "Tester",
          email: row[3] || "",
          device: row[4] || "Android",
          role: row[5] || "Tester",
          status: row[6] || "Pending Google Cloud"
        });
      }
    }

    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      testers: testers
    })).setMimeType(ContentService.MimeType.JSON);

  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

function getOrCreateSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName("Testers");
  if (!sheet) {
    sheet = ss.getActiveSheet();
    sheet.setName("Testers");
  }

  // Check headers
  if (sheet.getLastRow() === 0) {
    const headers = ["ID", "Timestamp", "Name", "Gmail Address", "Device Model", "Use Case", "Google Cloud Status"];
    sheet.appendRow(headers);
    sheet.getRange(1, 1, 1, headers.length).setFontWeight("bold").setBackground("#00A884").setFontColor("#FFFFFF");
    sheet.setFrozenRows(1);
  }

  return sheet;
}

function sendNotificationEmail(name, email, device, role, timestamp) {
  const subject = `🚀 [MemChat Beta] New Tester Registration: ${email}`;
  const body = 
    `Hello,\n\n` +
    `A new tester has just registered for the MemChat Private Beta:\n\n` +
    `• Name: ${name}\n` +
    `• Gmail: ${email}\n` +
    `• Device: ${device}\n` +
    `• Primary Use Case: ${role}\n` +
    `• Registered At: ${timestamp}\n\n` +
    `IMPORTANT NEXT STEP:\n` +
    `Copy this Gmail (${email}) and add it to your Google Cloud Console:\n` +
    `APIs & Services > OAuth Consent Screen > Test Users.\n\n` +
    `You can view all registered testers directly inside your Google Sheet.\n\n` +
    `— MemChat Notification Bot`;

  MailApp.sendEmail(ADMIN_EMAIL, subject, body);
}
