import { Router } from 'express';
import {
  getMyNotifications,
  markAsRead,
  markAllAsRead,
  broadcastNotification,
} from '../controllers/notification.controller';
import { authenticateToken, requireRole } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.get('/my', getMyNotifications);
router.patch('/:id/read', markAsRead);
router.patch('/read-all', markAllAsRead);
router.post('/broadcast', requireRole('ADMIN'), broadcastNotification);

export default router;
