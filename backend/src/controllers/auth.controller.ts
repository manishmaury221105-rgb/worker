import { Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { prisma } from '../prisma';
import { config } from '../config';
import { AuthRequest } from '../middleware/auth.middleware';

export const login = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { identifier, email, phone, password } = req.body;
    const loginId = identifier || email || phone;

    if (!loginId || !password) {
      res.status(400).json({
        success: false,
        message: 'Please provide email/phone and password',
      });
      return;
    }

    const user = await prisma.user.findFirst({
      where: {
        OR: [
          { email: loginId.trim().toLowerCase() },
          { phone: loginId.trim() },
        ],
      },
    });

    if (!user) {
      res.status(401).json({
        success: false,
        message: 'Invalid credentials. User not found.',
      });
      return;
    }

    if (user.status === 'INACTIVE') {
      res.status(403).json({
        success: false,
        message: 'Your account is deactivated. Please contact admin.',
      });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) {
      res.status(401).json({
        success: false,
        message: 'Invalid password. Please try again.',
      });
      return;
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role, name: user.name },
      config.jwtSecret,
      { expiresIn: '7d' }
    );

    const { password: _, ...userData } = user;

    res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token,
        user: userData,
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Login failed',
    });
  }
};

export const register = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const {
      name,
      email,
      phone,
      password,
      role = 'WORKER',
      department = 'General',
      designation = 'Worker',
      monthlySalary = 20000,
      hourlyRate = 100,
      address,
      emergencyContact,
      bankAccount,
      upiId,
    } = req.body;

    if (!name || !email || !phone || !password) {
      res.status(400).json({
        success: false,
        message: 'Name, email, phone, and password are required',
      });
      return;
    }

    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { email: email.trim().toLowerCase() },
          { phone: phone.trim() },
        ],
      },
    });

    if (existingUser) {
      res.status(409).json({
        success: false,
        message: 'User with this email or phone already exists',
      });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const user = await prisma.user.create({
      data: {
        name: name.trim(),
        email: email.trim().toLowerCase(),
        phone: phone.trim(),
        password: hashedPassword,
        role,
        department,
        designation,
        monthlySalary: Number(monthlySalary),
        hourlyRate: Number(hourlyRate),
        address,
        emergencyContact,
        bankAccount,
        upiId,
      },
    });

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role, name: user.name },
      config.jwtSecret,
      { expiresIn: '7d' }
    );

    const { password: _, ...userData } = user;

    res.status(201).json({
      success: true,
      message: 'Registration successful',
      data: {
        token,
        user: userData,
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Registration failed',
    });
  }
};

export const getMe = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      include: {
        _count: {
          select: {
            assignedTasks: { where: { status: { in: ['PENDING', 'IN_PROGRESS'] } } },
            leaves: { where: { status: 'PENDING' } },
            notifications: { where: { isRead: false } },
          },
        },
      },
    });

    if (!user) {
      res.status(404).json({ success: false, message: 'User not found' });
      return;
    }

    const { password: _, ...userData } = user;

    res.status(200).json({
      success: true,
      data: {
        ...userData,
        unreadNotificationsCount: user._count.notifications,
        activeTasksCount: user._count.assignedTasks,
        pendingLeavesCount: user._count.leaves,
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch user profile',
    });
  }
};

export const updateProfile = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { name, phone, address, emergencyContact, bankAccount, upiId, avatarUrl, fcmToken } = req.body;

    const updatedUser = await prisma.user.update({
      where: { id: req.user.id },
      data: {
        ...(name && { name: name.trim() }),
        ...(phone && { phone: phone.trim() }),
        ...(address !== undefined && { address }),
        ...(emergencyContact !== undefined && { emergencyContact }),
        ...(bankAccount !== undefined && { bankAccount }),
        ...(upiId !== undefined && { upiId }),
        ...(avatarUrl !== undefined && { avatarUrl }),
        ...(fcmToken !== undefined && { fcmToken }),
      },
    });

    const { password: _, ...userData } = updatedUser;

    res.status(200).json({
      success: true,
      message: 'Profile updated successfully',
      data: userData,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to update profile',
    });
  }
};

export const changePassword = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { currentPassword, newPassword } = req.body;

    if (!currentPassword || !newPassword) {
      res.status(400).json({
        success: false,
        message: 'Current password and new password are required',
      });
      return;
    }

    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
    });

    if (!user) {
      res.status(404).json({ success: false, message: 'User not found' });
      return;
    }

    const isMatch = await bcrypt.compare(currentPassword, user.password);
    if (!isMatch) {
      res.status(400).json({
        success: false,
        message: 'Incorrect current password',
      });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(newPassword, salt);

    await prisma.user.update({
      where: { id: req.user.id },
      data: { password: hashedPassword },
    });

    res.status(200).json({
      success: true,
      message: 'Password changed successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to change password',
    });
  }
};
