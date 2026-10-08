import { Router } from 'express';
import {
  getAllTasks,
  getMyTasks,
  createTask,
  updateTaskStatus,
  updateTask,
  deleteTask,
} from '../controllers/task.controller';
import { authenticateToken, requireRole } from '../middleware/auth.middleware';

const router = Router();

router.use(authenticateToken);

router.get('/', getAllTasks);
router.get('/my-tasks', getMyTasks);
router.post('/', requireRole('ADMIN'), createTask);
router.patch('/:id/status', updateTaskStatus);
router.put('/:id', requireRole('ADMIN'), updateTask);
router.delete('/:id', requireRole('ADMIN'), deleteTask);

export default router;
