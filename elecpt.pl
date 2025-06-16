#!/usr/bin/perl
use strict;
use warnings;
use File::Path qw(make_path);
use Cwd;
use Term::ANSIColor qw(colored);

# Terminal colors and formatting
sub print_header {
    my $text = shift;
    print colored("=" x 60, 'cyan') . "\n";
    print colored(" " x ((60 - length($text)) / 2) . $text, 'bold cyan') . "\n";
    print colored("=" x 60, 'cyan') . "\n\n";
}

sub print_step {
    my ($step, $description) = @_;
    print colored("[$step]", 'bold green') . " " . colored($description, 'white') . "\n";
}

sub print_success {
    my $text = shift;
    print colored("OK ", 'bold green') . colored($text, 'green') . "\n";
}

sub print_error {
    my $text = shift;
    print colored("ERROR ", 'bold red') . colored($text, 'red') . "\n";
}

sub print_info {
    my $text = shift;
    print colored("INFO ", 'bold blue') . colored($text, 'blue') . "\n";
}

sub print_progress {
    my $text = shift;
    print colored("PROGRESS ", 'bold yellow') . colored($text, 'yellow') . "\n";
}

# Configuration
my $project_name = "meine-electron-app";
my $desktop_path = "$ENV{HOME}/Schreibtisch/$project_name";

print_header("ELECTRON APP GENERATOR");
print_info("Erstelle moderne Electron-App mit React-Style Interface");
print "\n";

# 1. Verzeichnis erstellen
print_step("1/7", "Erstelle Projektverzeichnis...");
if (make_path($desktop_path)) {
    print_success("Verzeichnis erstellt: $desktop_path");
} else {
    print_error("Konnte Verzeichnis nicht erstellen: $!");
    die;
}

# 2. Ins Verzeichnis wechseln
print_step("2/7", "Wechsle ins Projektverzeichnis...");
if (chdir $desktop_path) {
    print_success("Verzeichnis gewechselt");
} else {
    print_error("Konnte nicht ins Verzeichnis wechseln: $!");
    die;
}

# 3. Node-Projekt initialisieren
print_step("3/7", "Initialisiere Node.js Projekt...");
if (system("npm init -y > /dev/null 2>&1") == 0) {
    print_success("package.json erstellt");
} else {
    print_error("npm init fehlgeschlagen");
    die;
}

# 4. Electron installieren
print_step("4/7", "Installiere Electron...");
print_progress("Das kann einen Moment dauern...");
if (system("npm install electron --save-dev > /dev/null 2>&1") == 0) {
    print_success("Electron erfolgreich installiert");
} else {
    print_error("Electron Installation fehlgeschlagen");
    die;
}

# 5. package.json anpassen
print_step("5/7", "Konfiguriere package.json...");
open(my $pkg, "+<", "package.json") or die "Kann package.json nicht öffnen: $!";
my $json = do { local $/; <$pkg> };

# main auf main.js setzen
$json =~ s/"main":\s*".*?"/"main": "main.js"/;

# scripts komplett auf "start": "electron ." setzen
if ($json =~ /"scripts":\s*{.*?}/s) {
    $json =~ s/"scripts":\s*{.*?}/"scripts": {\n    "start": "electron ."\n  }/s;
} else {
    $json =~ s/({)/$1\n  "scripts": {\n    "start": "electron ."\n  },/;
}

seek($pkg, 0, 0);
print $pkg $json;
truncate($pkg, tell($pkg));
close($pkg);
print_success("package.json konfiguriert");

# 6. Dateien erstellen
print_step("6/7", "Erstelle Anwendungsdateien...");

# main.js
open(my $main_fh, ">", "main.js") or die "Kann main.js nicht erstellen: $!";
print $main_fh <<'MAIN';
const { app, BrowserWindow } = require('electron');
const path = require('path');

function createWindow() {
  const win = new BrowserWindow({
    width: 1200,
    height: 800,
    webPreferences: {
      nodeIntegration: true,
      contextIsolation: false
    },
    icon: path.join(__dirname, 'assets/icon.png'),
    titleBarStyle: 'default',
    show: false
  });

  win.loadFile('index.html');
  
  // Zeige Fenster wenn bereit
  win.once('ready-to-show', () => {
    win.show();
  });

  // Entwickler-Tools in Development
  if (process.env.NODE_ENV === 'development') {
    win.webContents.openDevTools();
  }
}

app.whenReady().then(() => {
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});
MAIN
close($main_fh);
print_success("main.js erstellt");

# index.html - Vereinfacht
open(my $html_fh, ">", "index.html") or die "Kann index.html nicht erstellen: $!";
print $html_fh <<'HTML';
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Meine Electron App</title>
  <link rel="stylesheet" href="styles.css">
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
</head>
<body>
  <div id="root">
    <div class="app">
      <header class="app-header">
        <h1 class="app-title">Willkommen bei Electron</h1>
        <p class="app-description">
          Diese Anwendung wurde mit Electron erstellt und kombiniert die Flexibilität von Web-Technologien mit der Power einer Desktop-Anwendung.
        </p>
      </header>
    </div>
  </div>

  <script>
    document.addEventListener('DOMContentLoaded', function() {
      console.log('Electron App gestartet!');
    });
  </script>
</body>
</html>
HTML
close($html_fh);
print_success("index.html erstellt");

# styles.css - Vereinfacht
open(my $css_fh, ">", "styles.css") or die "Kann styles.css nicht erstellen: $!";
print $css_fh <<'CSS';
:root {
  --primary-color: #61dafb;
  --background-color: #282c34;
  --text-color: #ffffff;
  --text-secondary: #abb2bf;
}

* {
  margin: 0;
  padding: 0;
  box-sizing: border-box;
}

body {
  font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  background: var(--background-color);
  color: var(--text-color);
  line-height: 1.6;
}

#root {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}

.app {
  width: 100%;
  max-width: 800px;
  padding: 2rem;
}

.app-header {
  text-align: center;
  animation: fadeInUp 0.8s ease-out;
}

.app-title {
  font-size: 3rem;
  font-weight: 700;
  margin-bottom: 2rem;
  background: linear-gradient(135deg, var(--primary-color), #528bff);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.app-description {
  font-size: 1.2rem;
  color: var(--text-secondary);
  max-width: 600px;
  margin: 0 auto;
  line-height: 1.8;
}

@keyframes fadeInUp {
  from {
    opacity: 0;
    transform: translateY(30px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Responsive Design */
@media (max-width: 768px) {
  .app {
    padding: 1rem;
  }
  
  .app-title {
    font-size: 2rem;
  }

  .app-description {
    font-size: 1rem;
  }
}
CSS
close($css_fh);
print_success("styles.css erstellt");

print_step("7/7", "Finalisiere Setup...");
print_success("Alle Dateien erfolgreich erstellt");

print "\n";
print_header("SETUP ABGESCHLOSSEN");
print_success("Electron-App '$project_name' wurde erfolgreich erstellt!");
print_info("Projektverzeichnis: $desktop_path");
print "\n";

# 7. npm start automatisch ausführen
print_progress("Starte die Electron-App...");
print colored("LOADING ", 'yellow') . colored("App wird gestartet, bitte warten...", 'yellow') . "\n\n";

if (system("npm start") == 0) {
    print_success("App erfolgreich gestartet!");
} else {
    print_error("Fehler beim Starten der App");
    print_info("Versuche manuell: cd '$desktop_path' && npm start");
}

print "\n";
print colored("SUCCESS ", 'bold green') . colored("Viel Spass mit deiner neuen Electron-App!", 'bold green') . "\n";
print colored("TIPP ", 'blue') . colored("Bearbeite die Dateien und starte neu mit 'npm start'", 'blue') . "\n";