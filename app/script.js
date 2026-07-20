/**
 * Azure Cloud-Native DevSecOps Supply Chain Security
 * Demo Service Payload Script
 * 
 * Container Image này đã được xác nhận (Allowed) bởi Kyverno Admission Controller trên AKS
 * sau khi vượt qua các bước kiểm tra SLSA Provenance Level 3, Syft SBOM và Cosign Signature.
 */

document.addEventListener('DOMContentLoaded', () => {
    console.log("==========================================================================");
    console.log(" [SECURITY AUDIT] Azure Cloud-Native Supply Chain Security Payload Loaded ");
    console.log(" [SLSA LEVEL 3]   Build environment verified via GitHub Actions / ACR    ");
    console.log(" [SYFT SBOM]      SPDX-JSON software bill of materials attached          ");
    console.log(" [SIGSTORE]       ECDSA Cryptographic signature Cosign verified          ");
    console.log(" [ZERO TRUST]     Kyverno Admission Controller on AKS allowed deployment ");
    console.log("==========================================================================");
});
