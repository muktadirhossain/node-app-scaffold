# Node.js Application Scaffold

## Just Wanna use this Tool ?
`Run this Command in your terminal`
```bash
curl -s https://raw.githubusercontent.com/muktadirhossain/node-app-scaffold/main/setup.sh -o setup.sh && bash setup.sh
```

## Description

This repository contains a bash script that sets up a basic Node.js application scaffold using Express.js. The scaffold follows the MVC (Model-View-Controller) architecture, with support for JWT-based authentication, error handling, rate limiting, and MongoDB integration.

## Features

- **Node.js & Express.js**: A robust foundation for building web applications.
- **MVC Architecture**: Organizes your application for maintainability and scalability.
- **JWT Authentication**: Secure user authentication with session management.
- **Environment Variable Management**: Uses `dotenv` for configuration.
- **Security Middleware**: Implemented using `helmet`, `cors`, and `express-rate-limit`.
- **MongoDB Connection**: Integrated with Mongoose for database management.
- **Logging**: Error logging with customizable logging paths.
- **Basic Project Structure**: Automatically creates necessary directories and files.

## Installation

To create a new Node.js application scaffold:

1. Open your `terminal`.
2. `Run` the following command to download and execute the setup script:
```bash
curl -s https://raw.githubusercontent.com/muktadirhossain/node-app-scaffold/main/setup.sh -o setup.sh && bash setup.sh
```
3. **Follow the prompts** to enter your `project name`.

## Usage

Once the setup script completes, you will have a new directory with your project name containing:

- A configured `package.json` file.
- Folders for MVC structure (`controllers`, `models`, `routes`, etc.).
- Basic application files (`app.js`, `server.js`).
- A `.env` file for environment variables.
- A README file with instructions.

### Run the Application

To run your application:

1. Navigate into your project directory:
   ```bash
   cd your-project-name
   ```

2. Install the necessary dependencies (if not done automatically):
   ```bash
   npm install
   ```

3. Start the application:
   ```bash
   npm start
   ```

## Configuration

### Environment Variables

Configure your application by editing the `.env` file. You can set the following variables:

```env
APP_URL=http://localhost:3000
PORT=3000
MONGO_URI=mongodb://127.0.0.1:27017/your_db_name
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=1h
```

## Contributing

Contributions are welcome! If you have suggestions for improvements or features, please feel free to create an issue or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- [Express.js](https://expressjs.com/) for its robust web framework.
- [Mongoose](https://mongoosejs.com/) for simplifying MongoDB interactions.
- [JSON Web Tokens](https://jwt.io/) for secure user authentication.
```

### How to Customize

- Replace `yourusername` in the `curl` command with your actual GitHub username.
- Customize the MongoDB URI and JWT secret key in the example `.env` section.
- Modify the acknowledgments and any additional features as necessary.

This README provides a solid foundation for users to understand how to use your project. Let me know if you'd like to add or modify anything!