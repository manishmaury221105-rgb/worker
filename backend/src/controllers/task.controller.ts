import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export const getAllTasks = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { status, priority, assignedToId, search } = req.query;

    const where: any = {};

    if (status && status !== 'ALL') {
      where.status = String(status);
    }

    if (priority && priority !== 'ALL') {
      where.priority = String(priority);
    }

    if (assignedToId) {
      where.assignedToId = String(assignedToId);
    }

    if (search) {
      const q = String(search).trim();
      where.OR = [
        { title: { contains: q, mode: 'insensitive' } },
        { description: { contains: q, mode: 'insensitive' } },
        { location: { contains: q, mode: 'insensitive' } },
      ];
    }

    const tasks = await prisma.task.findMany({
      where,
      include: {
        assignedTo: {
          select: {
            id: true,
            name: true,
            email: true,
            phone: true,
            department: true,
            designation: true,
            avatarUrl: true,
          },
        },
        createdBy: {
          select: {
            id: true,
            name: true,
          },
        },
      },
      orderBy: [{ priority: 'desc' }, { createdAt: 'desc' }],
    });

    res.status(200).json({
      success: true,
      count: tasks.length,
      data: tasks,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch tasks',
    });
  }
};

export const getMyTasks = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { status } = req.query;

    const where: any = { assignedToId: req.user.id };

    if (status && status !== 'ALL') {
      where.status = String(status);
    }

    const tasks = await prisma.task.findMany({
      where,
      include: {
        createdBy: {
          select: { id: true, name: true },
        },
      },
      orderBy: [{ status: 'asc' }, { priority: 'desc' }, { createdAt: 'desc' }],
    });

    res.status(200).json({
      success: true,
      count: tasks.length,
      data: tasks,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch my tasks',
    });
  }
};

export const createTask = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { title, description, assignedToId, priority = 'MEDIUM', dueDate, location } = req.body;

    if (!title || !description || !assignedToId) {
      res.status(400).json({
        success: false,
        message: 'Title, description and assigned worker are required',
      });
      return;
    }

    const task = await prisma.task.create({
      data: {
        title: title.trim(),
        description: description.trim(),
        assignedToId,
        createdById: req.user.id,
        priority,
        dueDate: dueDate ? new Date(dueDate) : null,
        location: location ? location.trim() : null,
      },
      include: {
        assignedTo: {
          select: { id: true, name: true, phone: true },
        },
      },
    });

    // Send in-app notification to worker
    await prisma.notification.create({
      data: {
        userId: assignedToId,
        title: `New Task: ${title}`,
        message: `You have been assigned a new task: ${title}. Priority: ${priority}`,
        type: 'TASK',
      },
    });

    res.status(201).json({
      success: true,
      message: 'Task created and assigned successfully',
      data: task,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to create task',
    });
  }
};

export const updateTaskStatus = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { status, completionNotes } = req.body;

    if (!status) {
      res.status(400).json({
        success: false,
        message: 'Status is required',
      });
      return;
    }

    const isCompleted = status === 'COMPLETED';

    const task = await prisma.task.update({
      where: { id: id as string },
      data: {
        status,
        ...(completionNotes && { completionNotes }),
        completedAt: isCompleted ? new Date() : null,
      },
      include: {
        assignedTo: { select: { name: true } },
      },
    });

    res.status(200).json({
      success: true,
      message: `Task status updated to ${status}`,
      data: task,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to update task status',
    });
  }
};

export const updateTask = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const { title, description, assignedToId, priority, status, dueDate, location } = req.body;

    const task = await prisma.task.update({
      where: { id: id as string },
      data: {
        ...(title && { title: title.trim() }),
        ...(description && { description: description.trim() }),
        ...(assignedToId && { assignedToId }),
        ...(priority && { priority }),
        ...(status && { status }),
        ...(dueDate !== undefined && { dueDate: dueDate ? new Date(dueDate) : null }),
        ...(location !== undefined && { location }),
      },
    });

    res.status(200).json({
      success: true,
      message: 'Task updated successfully',
      data: task,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to update task',
    });
  }
};

export const deleteTask = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    await prisma.task.delete({
      where: { id: id as string },
    });

    res.status(200).json({
      success: true,
      message: 'Task deleted successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to delete task',
    });
  }
};
