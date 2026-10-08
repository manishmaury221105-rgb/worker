import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export const getMyNotifications = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const notifications = await prisma.notification.findMany({
      where: { userId: req.user.id },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    const unreadCount = await prisma.notification.count({
      where: { userId: req.user.id, isRead: false },
    });

    res.status(200).json({
      success: true,
      unreadCount,
      data: notifications,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch notifications',
    });
  }
};

export const markAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const notification = await prisma.notification.update({
      where: { id: id as string },
      data: { isRead: true },
    });

    res.status(200).json({
      success: true,
      data: notification,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to update notification',
    });
  }
};

export const markAllAsRead = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    await prisma.notification.updateMany({
      where: { userId: req.user.id, isRead: false },
      data: { isRead: true },
    });

    res.status(200).json({
      success: true,
      message: 'All notifications marked as read',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to mark all notifications as read',
    });
  }
};

export const broadcastNotification = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { title, message, type = 'SYSTEM', department } = req.body;

    if (!title || !message) {
      res.status(400).json({
        success: false,
        message: 'Title and message are required',
      });
      return;
    }

    const where: any = { role: 'WORKER', status: 'ACTIVE' };
    if (department && department !== 'ALL') {
      where.department = department;
    }

    const workers = await prisma.user.findMany({
      where,
      select: { id: true },
    });

    const notificationsData = workers.map((w) => ({
      userId: w.id,
      title: title.trim(),
      message: message.trim(),
      type: type as any,
    }));

    await prisma.notification.createMany({
      data: notificationsData,
    });

    res.status(201).json({
      success: true,
      message: `Broadcast sent to ${workers.length} workers successfully`,
      count: workers.length,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to broadcast notification',
    });
  }
};
