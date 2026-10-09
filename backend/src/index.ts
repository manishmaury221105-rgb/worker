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

// Global Error Handler
app.use(errorHandler);

const server = app.listen(config.port, '0.0.0.0', () => {
  console.log(`\n⚡ Worker Management Backend is running on http://0.0.0.0:${config.port}`);
  console.log(`⚡ Health Check: http://localhost:${config.port}/api/health\n`);
});

// Handle graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
  });
});

export default app;
