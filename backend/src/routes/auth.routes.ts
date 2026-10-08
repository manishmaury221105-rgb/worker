import { Router } from 'express';
import {
  login,
  register,
  getMe,
  updateProfile,
  changePassword,
} from '../controllers/auth.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.post('/login', login);
router.post('/register', register);
router.get('/me', authenticateToken, getMe);
router.put('/profile', authenticateToken, updateProfile);
router.post('/change-password', authenticateToken, changePassword);

export default router;
