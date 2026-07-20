// SBOM Mock Data simulating what Syft / Trivy exports for Nginx Alpine
const sbomPackages = [
    { name: 'alpine-baselayout', version: '3.6.5-r0', type: 'apk', license: 'GPL-2.0-only', cve: '0 Vulnerabilities (Clean)' },
    { name: 'alpine-keys', version: '2.4-r1', type: 'apk', license: 'MIT', cve: '0 Vulnerabilities (Clean)' },
    { name: 'busybox', version: '1.36.1-r19', type: 'apk', license: 'GPL-2.0', cve: '0 Vulnerabilities (Clean)' },
    { name: 'ca-certificates-bundle', version: '20240226-r0', type: 'apk', license: 'MPL-2.0', cve: '0 Vulnerabilities (Clean)' },
    { name: 'libcrypto3 (OpenSSL)', version: '3.1.4-r6', type: 'apk', license: 'Apache-2.0', cve: '0 Vulnerabilities (Clean)' },
    { name: 'libssl3 (OpenSSL)', version: '3.1.4-r6', type: 'apk', license: 'Apache-2.0', cve: '0 Vulnerabilities (Clean)' },
    { name: 'nginx', version: '1.26.0-r0', type: 'apk', license: 'BSD-2-Clause', cve: '0 Vulnerabilities (Clean)' },
    { name: 'pcre2', version: '10.43-r0', type: 'apk', license: 'BSD-3-Clause', cve: '0 Vulnerabilities (Clean)' },
    { name: 'zlib', version: '1.3.1-r0', type: 'apk', license: 'Zlib', cve: '0 Vulnerabilities (Clean)' }
];

// Populate SBOM Table
function renderSBOMTable(packages) {
    const tbody = document.getElementById('sbomTableBody font-mono') || document.querySelector('.sbom-table tbody');
    tbody.innerHTML = '';
    
    packages.forEach(pkg => {
        const row = document.createElement('tr');
        row.innerHTML = `
            <td class="font-mono" style="font-weight:600; color: #60a5fa;">${pkg.name}</td>
            <td class="font-mono">${pkg.version}</td>
            <td><span class="tag" style="background: rgba(59,130,246,0.15); color: #93c5fd;">${pkg.type}</span></td>
            <td>${pkg.license}</td>
            <td><span class="cve-badge">✓ ${pkg.cve}</span></td>
        `;
        tbody.appendChild(row);
    });
}

// Search filter logic
document.getElementById('sbomSearch').addEventListener('input', (e) => {
    const keyword = e.target.value.toLowerCase();
    const filtered = sbomPackages.filter(p => 
        p.name.toLowerCase().includes(keyword) || 
        p.license.toLowerCase().includes(keyword) ||
        p.type.toLowerCase().includes(keyword)
    );
    renderSBOMTable(filtered);
});

// Live Verification Simulation
document.getElementById('verifyBtn').addEventListener('click', () => {
    const overlay = document.getElementById('terminalOverlay');
    const output = document.getElementById('terminalOutput');
    overlay.classList.remove('hidden');
    output.innerHTML = '';
    
    const steps = [
        '[INFO] Connecting to Azure Container Registry (ACR)... OK',
        '[INFO] Retrieving OCI Image Manifest: sha256:4e7a8f9b2d1c...',
        '[INFO] Downloading Cosign Public Key (keys/cosign.pub)... OK',
        '[VERIFY] Cryptographic ECDSA signature check against Image SHA256...',
        '<span style="color:#34d399;">[SUCCESS] Cosign Signature Verified! Image is authentic and unmodified.</span>',
        '[VERIFY] Fetching attached SBOM attestation (SPDX-JSON Format)... OK',
        '[VERIFY] Checking SLSA Provenance Level 3 Builder identity...',
        '<span style="color:#34d399;">[SUCCESS] SLSA Attestation match! Source: github.com/azure-student/DemoC5</span>',
        '<span style="color:#60a5fa; font-weight:bold;">[ADMISSION ALLOWED] Kyverno Policy Engine on AKS authorized pod deployment.</span>'
    ];
    
    let delay = 0;
    steps.forEach((step, index) => {
        setTimeout(() => {
            output.innerHTML += `<div>> ${step}</div>`;
            output.scrollTop = output.scrollHeight;
        }, delay);
        delay += 350;
    });
});

// Uptime Counter Simulation
let seconds = 0;
setInterval(() => {
    seconds++;
    const h = String(Math.floor(seconds / 3600)).padStart(2, '0');
    const m = String(Math.floor((seconds % 3600) / 60)).padStart(2, '0');
    const s = String(seconds % 60).padStart(2, '0');
    document.getElementById('uptimeCounter').textContent = `${h}:${m}:${s}`;
}, 1000);

// Initial Render
renderSBOMTable(sbomPackages);
