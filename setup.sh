#!/bin/bash

# Function to show loading message
show_loader() {
  echo -n "Installing dependencies"
  while :; do
    echo -n "."
    sleep 1
  done &
  LOADER_PID=$!
}

# Function to stop the loader
stop_loader() {
  kill "$LOADER_PID"
  wait "$LOADER_PID" 2>/dev/null
  echo -e "\nDependencies installed successfully!"
}

# Ask for project name
read -p "Enter your project name: " projectName

# Create project directory
mkdir -p $projectName
cd $projectName

# Initialize npm project
npm init -y

# Create package.json with specified structure
cat <<EOL > package.json
{
  "name": "$projectName",
  "version": "1.0.0",
  "description": "",
  "main": "server.js",
  "type": "module",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js",
    "prod": "NODE_ENV=production node server.js"
  },
  "keywords": [],
  "author": "",
  "license": "ISC",
  "dependencies": {
    "bcryptjs": "",
    "cors": "",
    "dotenv": "",
    "express": "",
    "express-async-errors": "",
    "express-rate-limit": "",
    "helmet": "",
    "http-status-codes": "",
    "jsonwebtoken": "",
    "mongoose": "",
    "morgan": ""
  },
  "devDependencies": {
    "nodemon": ""
  }
}
EOL

show_loader

# Install necessary packages
npm install express mongoose bcryptjs jsonwebtoken dotenv cors express-rate-limit helmet morgan http-status-codes express-async-errors

stop_loader

# Create folders for MVC structure, middleware, and config
mkdir -p controllers models routes utils middlewares logs config public

# Create .env file
cat <<EOL > .env
APP_URL=http://localhost:3000
PORT=3000
MONGO_URI=mongodb://127.0.0.1:27017
JWT_SECRET=your_jwt_secret_key
JWT_EXPIRES_IN=1h
EOL

# Create app.js
cat <<EOL > app.js
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import morgan from 'morgan';
import path from 'path';
import rateLimit from 'express-rate-limit';
import { errorHandler } from './middlewares/errorHandler.js';
import authRoutes from './routes/authRoutes.js';
import connectDB from './config/connectDB.js';
import { AppError } from './utils/AppError.js';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

// Connect to DB
connectDB();

const app = express();

// Set security HTTP headers
app.use(helmet());

// Enable CORS
app.use(cors());

// Rate limiter to prevent DOS attacks
const limiter = rateLimit({
  max: 100,
  windowMs: 60 * 60 * 1000, // 1 hour
  message: 'Too many requests from this IP, please try again later'
});
app.use('/api', limiter);

// Development logging
if (process.env.NODE_ENV === 'development') {
  app.use(morgan('dev'));
}

// Parse JSON request bodies
app.use(express.json());

// Serve static files from the "public" folder
const __dirname = path.resolve(); // Get the current directory
app.use(express.static(path.join(__dirname, 'public'))); // Serve the "public" directory

// Routes
app.use('/api/v1/auth', authRoutes);

// Handle unknown routes
app.all('*', (req, res, next) => {
  const err = new AppError(\`Can't find \${req.originalUrl} on this server!\`, 404);
  next(err);
});

// Global error handling middleware
app.use(errorHandler);

export default app;
EOL

# Create server.js
cat <<EOL > server.js
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';
import { fileURLToPath } from 'url';
import app from './app.js';
import { PORT } from './config/constants.js';

// Load environment variables
dotenv.config();

// Get the current directory path
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const port = PORT || 3000;

const server = app.listen(port, () => {
  console.log(\`App running on http://localhost:\${port}\`);
});

// Error logging for production
process.on('unhandledRejection', (err) => {
  console.error('Unhandled rejection! Shutting down...');
  fs.appendFileSync(path.join(__dirname, 'logs', 'error.log'), \`\${new Date()} - Unhandled Rejection: \${err.message}\\n\`);
  server.close(() => {
    process.exit(1);
  });
});
EOL

# Create authController.js
cat <<EOL > controllers/authController.js
import jwt from 'jsonwebtoken';
import User from '../models/userModel.js';
import { AppError } from '../utils/AppError.js';
import catchAsync from '../utils/catchAsync.js';
import { StatusCodes } from 'http-status-codes';
import { JWT_EXPIRES_IN, JWT_SECRET } from '../config/constants.js';

const signToken = (id, sessionId) => {
  return jwt.sign({ id, sessionId }, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN });
};

export const login = catchAsync(async (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return next(new AppError('Please provide email and password', StatusCodes.BAD_REQUEST));
  }

  const user = await User.findOne({ email }).select('+password');
  if (!user || !(await user.correctPassword(password, user.password))) {
    return next(new AppError('Incorrect email or password', StatusCodes.UNAUTHORIZED));
  }

  const sessionId = Date.now().toString();
  user.sessionId = sessionId;
  await user.save();

  const token = signToken(user._id, sessionId);
  res.status(StatusCodes.OK).json({ status: 'success', token });
});

export const protect = catchAsync(async (req, res, next) => {
  let token;
  if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
    token = req.headers.authorization.split(' ')[1];
  }

  if (!token) {
    return next(new AppError('You are not logged in! Please log in to get access', StatusCodes.UNAUTHORIZED));
  }

  const decoded = jwt.verify(token, JWT_SECRET);
  const currentUser = await User.findById(decoded.id);
  if (!currentUser) {
    return next(new AppError('The user belonging to this token no longer exists.', StatusCodes.UNAUTHORIZED));
  }

  if (currentUser.sessionId !== decoded.sessionId) {
    return next(new AppError('This token has been invalidated. Please log in again.', StatusCodes.UNAUTHORIZED));
  }

  req.user = currentUser;
  next();
});
EOL

# Create userModel.js
cat <<EOL > models/userModel.js
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: [true, 'Please provide your email'],
    unique: true,
    lowercase: true,
  },
  password: {
    type: String,
    required: [true, 'Please provide a password'],
    minlength: 8,
    select: false,
  },
  sessionId: String,
});

userSchema.pre('save', async function (next) {
  if (!this.isModified('password')) return next();
  this.password = await bcrypt.hash(this.password, 12);
  next();
});

userSchema.methods.correctPassword = async function (candidatePassword, userPassword) {
  return await bcrypt.compare(candidatePassword, userPassword);
};

const User = mongoose.model('User', userSchema);

export default User;
EOL

# Create authRoutes.js
cat <<EOL > routes/authRoutes.js
import express from 'express';
import { login, protect } from '../controllers/authController.js';

const router = express.Router();

router.post('/login', login);
router.get('/protected', protect, (req, res) => {
  res.status(200).json({ message: 'Access granted to protected route' });
});

export default router;
EOL

# Create errorHandler.js in middlewares folder
cat <<EOL > middlewares/errorHandler.js
import { StatusCodes } from 'http-status-codes';
import { fileURLToPath } from 'url';
import fs from 'fs';
import path from 'path';

// Get the current directory path
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export const errorHandler = (err, req, res, next) => {
  err.statusCode = err.statusCode || StatusCodes.INTERNAL_SERVER_ERROR;
  err.status = err.status || 'error';

  // Log error in production
  if (process.env.NODE_ENV === 'production') {
    fs.appendFileSync(path.join(__dirname, '..', 'logs', 'error.log'), \`\${new Date()} - \${err.message}\n \nStack: \${err.stack}\n\n---------------------------- X--------------------------------------- \n\n\`);

    return res.status(err.statusCode).json({
      status: err.status,
      message: err.message,
    });
  }

  return res.status(err.statusCode).json({
    status: err.status,
    message: err.message,
    stack: err.stack, // Include stack trace in development
    error: err, // Full error object for development
  });
};
EOL

# Create AppError.js in utils folder
cat <<EOL > utils/AppError.js
export class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.status = \`\${statusCode}\`.startsWith('4') ? 'fail' : 'error';
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}
EOL

# Create catchAsync.js in utils folder
cat <<EOL > utils/catchAsync.js
const catchAsync = (fn) => {
  return (req, res, next) => {
    fn(req, res, next).catch(next);
  };
};

export default catchAsync;
EOL

# Create connectDB.js in config folder
cat <<EOL > config/connectDB.js
import mongoose from 'mongoose';
import { MONGO_URI } from './constants.js';

const config = {
  isConnected: 0,
};

const connectDB = async () => {
  // Check if already connected to DB
  if (config.isConnected) {
    return;
  }

  const options = {
    dbName: "$projectName",
  };

  try {
    const { connection } = await mongoose.connect(MONGO_URI, options);
    config.isConnected = connection.readyState;

    console.log('✔️ Connected to DB 👍');
    console.log('↗️        HOST:', connection.host);
    console.log('↗️  HOST_NAME :', connection.name);
  } catch (error) {
    console.log('Failed to connect DB 💀💀💀');
    console.error(error.message);
    throw new Error(error);
  }
};

export default connectDB;
EOL

# Create connectDB.js in config folder
cat <<EOL > config/constants.js
import dotenv from 'dotenv';
dotenv.config()

export const APP_URL = process.env.APP_URL;
export const PORT = process.env.PORT;
export const MONGO_URI = process.env.MONGO_URI;
export const JWT_SECRET = process.env.JWT_SECRET;
export const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN;
EOL

# Create README.md
cat <<EOL > README.md
# Express MVC App

## Description

This is an Express.js application following the MVC (Model-View-Controller) architecture. It includes features such as JWT-based authentication, error handling, rate limiting, CORS, and more.

## Features

- JWT Authentication with session invalidation on multiple device logins
- Environment variable management via dotenv
- Express middleware for security headers, rate limiting, logging, etc.
- MongoDB connection management using Mongoose
- Structured app in MVC pattern

## How to run

1. Clone the repository.
2. Install dependencies using \`npm install\`.
3. Configure environment variables in the \`.env\` file.
4. Run the app using \`npm start\`.
EOL

# Output success message
echo "Project setup complete in $projectName!"
