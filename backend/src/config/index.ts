import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '5050', 10),
  jwtSecret: process.env.JWT_SECRET || 'worker_default_super_secret_jwt_key_2026',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '7d',
  nodeEnv: process.env.NODE_ENV || 'development',
  standardCheckInHour: 9, // 9:00 AM standard
  lateGraceMinutes: 30, // up to 9:30 AM before marked Late
};
