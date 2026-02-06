# AuditLab

An automated CIS benchmark audit tool for Windows 11 and Linux (Red Hat, Ubuntu) that runs compliance checks, generates reports, and manages settings through a simple, user-friendly GUI.

## Features

- **Multi-Platform Support**: Comprehensive CIS benchmark auditing for Windows 11 and Linux distributions (Red Hat, Ubuntu)
- **Automated Compliance Checks**: Run security configuration assessments against industry-standard CIS benchmarks
- **Report Generation**: Generate detailed audit reports with compliance status and recommendations
- **Settings Management**: Easily configure and manage audit parameters
- **User-Friendly Interface**: Intuitive GUI built with Electron for cross-platform compatibility

## Technologies

- **Electron**: Cross-platform desktop application framework
- **JavaScript/Node.js**: Core application logic
- **HTML/CSS**: User interface design

## Installation

### Prerequisites
- Node.js (v16 or higher)
- npm or yarn

### Setup

1. Clone the repository:
```bash
git clone https://github.com/AmeerSheikh02/AuditLab.git
cd AuditLab
```

2. Install dependencies:
```bash
npm install
```

3. Start the application:
```bash
npm start
```

## Usage

1. Launch AuditLab
2. Select your target operating system (Windows 11, Red Hat, or Ubuntu)
3. Choose the CIS benchmark level to audit against
4. Run the compliance check
5. Review the generated report and recommendations

## Development

### Running in Development Mode
```bash
npm start
```

### Building for Production
```bash
npm run build
```

## Project Structure

```
AuditLab/
├── src/              # Application source code
├── assets/           # Static assets
├── scripts/          # Utility scripts
└── main.js           # Electron main process
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

ISC

## Author

Ameer Sheikh

## Support

For issues, questions, or suggestions, please open an issue on the GitHub repository.
