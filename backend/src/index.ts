import express from 'express';
import cors from 'cors';
import { config } from './config';
import authRoutes from './routes/auth.routes';
import workerRoutes from './routes/worker.routes';
import attendanceRoutes from './routes/attendance.routes';
import taskRoutes from './routes/task.routes';
import leaveRoutes from './routes/leave.routes';
import salaryRoutes from './routes/salary.routes';
import expenseRoutes from './routes/expense.routes';
import notificationRoutes from './routes/notification.routes';
import reportRoutes from './routes/report.routes';
import { errorHandler, notFoundHandler } from './middleware/error.middleware';

const app = express();

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
}));

app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logger for development
if (config.nodeEnv === 'development') {
  app.use((req, res, next) => {
    console.log(`[${new Date().toISOString()}] ${req.method} ${req.url}`);
    next();
  });
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.status(200).json({
    status: 'ok',
    message: 'Worker Management API is running smoothly',
    timestamp: new Date().toISOString(),
    env: config.nodeEnv,
    version: '1.0.0',
  });
});

// API Routes
app.use('/api/auth', authRoutes);
app.use('/api/workers', workerRoutes);
app.use('/api/attendance', attendanceRoutes);
app.use('/api/tasks', taskRoutes);
app.use('/api/leaves', leaveRoutes);
app.use('/api/salary', salaryRoutes);
app.use('/api/expenses', expenseRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/reports', reportRoutes);

// Catch 404
app.use(notFoundHandler);

import { prisma } from './prisma';
import bcrypt from 'bcryptjs';

async function ensureAdminExists() {
  try {
    const admin = await prisma.user.findFirst({
      where: { phone: '9695718820' },
    });
    if (!admin) {
      const salt = await bcrypt.genSalt(10);
      const adminPassword = await bcrypt.hash('Aj@y', salt);
      await prisma.user.create({
        data: {
          name: 'अजय मौर्य (Admin)',
          email: 'ajay@laxminarayan.com',
          phone: '9695718820',
          password: adminPassword,
          role: 'ADMIN',
          department: 'Management',
          designation: 'Owner / Director',
          monthlySalary: 75000,
          hourlyRate: 400,
          status: 'ACTIVE',
          address: 'घमहापुर, चोरारी, जलालपुर रोड, मड़ियाहूँ, जौनपुर',
          emergencyContact: '+91 7304228743',
          bankAccount: 'HDFC0001234 - 50100234567890',
          upiId: 'ajay.maurya@okhdfcbank',
        },
      });
      console.log('⚡ Default Admin user ensured: 9695718820');
    }
  } catch (err) {
    console.error('Error ensuring admin user:', err);
  }
}

const server = app.listen(config.port, '0.0.0.0', () => {
  console.log(`\n⚡ Worker Management Backend is running on http://0.0.0.0:${config.port}`);
  console.log(`⚡ Health Check: http://localhost:${config.port}/api/health\n`);
  ensureAdminExists();
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

export default app;
