import { Response } from 'express';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';
import { AttendanceStatus } from '@prisma/client';

const getTodayDate = (): Date => {
  const now = new Date();
  return new Date(Date.UTC(now.getFullYear(), now.getMonth(), now.getDate()));
};

export const checkIn = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { latitude, longitude, address, notes } = req.body;
    const today = getTodayDate();
    const now = new Date();

    // Check if attendance is locked for today
    const lock = await prisma.attendanceLock.findUnique({
      where: { date: today },
    });

    if (lock && lock.isLocked) {
      res.status(403).json({
        success: false,
        message: 'आज की हाजिरी एडमिन द्वारा लॉक कर दी गई है (Attendance is locked by Admin).',
      });
      return;
    }

    const existing = await prisma.attendance.findUnique({
      where: {
        userId_date: {
          userId: req.user.id,
          date: today,
        },
      },
    });

    if (existing && existing.checkInTime) {
      res.status(400).json({
        success: false,
        message: 'You have already checked in for today',
        data: existing,
      });
      return;
    }

    // Determine if late (e.g. standard time is 9:30 AM)
    const hours = now.getHours();
    const minutes = now.getMinutes();
    const isLate = hours > 9 || (hours === 9 && minutes > 30);
    const status: AttendanceStatus = isLate ? 'LATE' : 'PRESENT';

    const attendance = await prisma.attendance.upsert({
      where: {
        userId_date: {
          userId: req.user.id,
          date: today,
        },
      },
      update: {
        checkInTime: now,
        checkInLat: latitude ? Number(latitude) : null,
        checkInLng: longitude ? Number(longitude) : null,
        checkInAddress: address || 'GPS Location Verified',
        status,
        notes: notes || undefined,
      },
      create: {
        userId: req.user.id,
        date: today,
        checkInTime: now,
        checkInLat: latitude ? Number(latitude) : null,
        checkInLng: longitude ? Number(longitude) : null,
        checkInAddress: address || 'GPS Location Verified',
        status,
        notes,
      },
    });

    // Create Notification
    await prisma.notification.create({
      data: {
        userId: req.user.id,
        title: isLate ? 'Check-in Recorded (Late)' : 'Check-in Successful',
        message: `You checked in today at ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}.`,
        type: 'ATTENDANCE',
      },
    });

    res.status(200).json({
      success: true,
      message: isLate ? 'Checked in successfully (Marked Late)' : 'Checked in successfully',
      data: attendance,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Check-in failed',
    });
  }
};

export const checkOut = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { latitude, longitude, address, notes } = req.body;
    const today = getTodayDate();
    const now = new Date();

    // Check if attendance is locked for today
    const lock = await prisma.attendanceLock.findUnique({
      where: { date: today },
    });

    if (lock && lock.isLocked) {
      res.status(403).json({
        success: false,
        message: 'आज की हाजिरी एडमिन द्वारा लॉक कर दी गई है (Attendance is locked by Admin).',
      });
      return;
    }

    const existing = await prisma.attendance.findUnique({
      where: {
        userId_date: {
          userId: req.user.id,
          date: today,
        },
      },
    });

    if (!existing || !existing.checkInTime) {
      res.status(400).json({
        success: false,
        message: 'You have not checked in today yet. Please check in first.',
      });
      return;
    }

    if (existing.checkOutTime) {
      res.status(400).json({
        success: false,
        message: 'You have already checked out for today',
        data: existing,
      });
      return;
    }

    const checkInTime = new Date(existing.checkInTime);
    const diffMs = now.getTime() - checkInTime.getTime();
    const workingHours = Math.max(0, Math.round((diffMs / (1000 * 60 * 60)) * 10) / 10);

    let finalStatus = existing.status;
    if (workingHours < 4 && workingHours > 0) {
      finalStatus = 'HALF_DAY';
    }

    const attendance = await prisma.attendance.update({
      where: { id: existing.id },
      data: {
        checkOutTime: now,
        checkOutLat: latitude ? Number(latitude) : null,
        checkOutLng: longitude ? Number(longitude) : null,
        checkOutAddress: address || 'GPS Location Verified',
        workingHours,
        status: finalStatus,
        notes: notes ? `${existing.notes || ''} ${notes}`.trim() : existing.notes,
      },
    });

    // Create Notification
    await prisma.notification.create({
      data: {
        userId: req.user.id,
        title: 'Check-out Successful',
        message: `You checked out at ${now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}. Total working time: ${workingHours} hrs.`,
        type: 'ATTENDANCE',
      },
    });

    res.status(200).json({
      success: true,
      message: 'Checked out successfully',
      data: attendance,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Check-out failed',
    });
  }
};

export const selfMarkAttendance = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { status, date } = req.body;
    const targetDate = date ? new Date(date) : getTodayDate();
    const normalizedDate = new Date(Date.UTC(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate()));

    // Check if attendance is locked for this date
    const lock = await prisma.attendanceLock.findUnique({
      where: { date: normalizedDate },
    });

    if (lock && lock.isLocked) {
      res.status(403).json({
        success: false,
        message: 'आज की हाजिरी एडमिन द्वारा लॉक कर दी गई है (Attendance is locked by Admin).',
      });
      return;
    }

    let workingHours = 8.0;
    let checkInTime: Date | null = new Date(normalizedDate.getFullYear(), normalizedDate.getMonth(), normalizedDate.getDate(), 9, 0);
    let checkOutTime: Date | null = new Date(normalizedDate.getFullYear(), normalizedDate.getMonth(), normalizedDate.getDate(), 17, 30);

    if (status === 'ABSENT') {
      workingHours = 0.0;
      checkInTime = null;
      checkOutTime = null;
    } else if (status === 'HALF_DAY') {
      workingHours = 4.0;
      checkOutTime = new Date(normalizedDate.getFullYear(), normalizedDate.getMonth(), normalizedDate.getDate(), 13, 0);
    }

    const attendance = await prisma.attendance.upsert({
      where: {
        userId_date: {
          userId: req.user.id,
          date: normalizedDate,
        },
      },
      update: {
        status,
        workingHours,
        checkInTime,
        checkOutTime,
      },
      create: {
        userId: req.user.id,
        date: normalizedDate,
        status,
        workingHours,
        checkInTime,
        checkOutTime,
      },
    });

    res.status(200).json({
      success: true,
      message: `Today's attendance marked as ${status}`,
      data: attendance,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to update attendance',
    });
  }
};

export const getTodayAttendance = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const today = getTodayDate();

    const [attendance, lock] = await Promise.all([
      prisma.attendance.findUnique({
        where: {
          userId_date: {
            userId: req.user.id,
            date: today,
          },
        },
      }),
      prisma.attendanceLock.findUnique({
        where: { date: today },
      }),
    ]);

    const isLocked = lock ? lock.isLocked : (attendance?.isLocked ?? false);

    res.status(200).json({
      success: true,
      isLocked,
      data: attendance ? { ...attendance, isLocked } : null,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch today attendance',
    });
  }
};

export const getMyAttendanceHistory = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    if (!req.user) {
      res.status(401).json({ success: false, message: 'Unauthorized' });
      return;
    }

    const { month, year, limit = 30 } = req.query;

    const where: any = { userId: req.user.id };

    if (month && year) {
      const m = Number(month) - 1;
      const y = Number(year);
      const startOfMonth = new Date(Date.UTC(y, m, 1));
      const endOfMonth = new Date(Date.UTC(y, m + 1, 0, 23, 59, 59));
      where.date = { gte: startOfMonth, lte: endOfMonth };
    }

    const records = await prisma.attendance.findMany({
      where,
      orderBy: { date: 'desc' },
      take: Number(limit),
    });

    // Summary calculations
    let totalPresent = 0;
    let totalLate = 0;
    let totalHalfDay = 0;
    let totalHours = 0;

    records.forEach((r) => {
      if (r.status === 'PRESENT') totalPresent++;
      if (r.status === 'LATE') { totalLate++; totalPresent++; }
      if (r.status === 'HALF_DAY') totalHalfDay++;
      totalHours += r.workingHours || 0;
    });

    res.status(200).json({
      success: true,
      summary: {
        totalPresent,
        totalLate,
        totalHalfDay,
        totalHours: Math.round(totalHours * 10) / 10,
        averageHours: records.length ? Math.round((totalHours / records.length) * 10) / 10 : 0,
      },
      data: records,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch attendance history',
    });
  }
};

export const getAllAttendance = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { date, workerId, department, status, startDate, endDate } = req.query;

    const where: any = {};

    if (workerId) {
      where.userId = String(workerId);
    }

    if (status && status !== 'ALL') {
      where.status = String(status);
    }

    if (date) {
      const d = new Date(String(date));
      const targetDate = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
      where.date = targetDate;
    } else if (startDate && endDate) {
      where.date = {
        gte: new Date(String(startDate)),
        lte: new Date(String(endDate)),
      };
    }

    if (department && department !== 'ALL') {
      where.user = {
        department: String(department),
      };
    }

    const records = await prisma.attendance.findMany({
      where,
      include: {
        user: {
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
      },
      orderBy: [{ date: 'desc' }, { checkInTime: 'desc' }],
    });

    res.status(200).json({
      success: true,
      count: records.length,
      data: records,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch attendance records',
    });
  }
};

export const manualMarkAttendance = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const {
      userId,
      date,
      status = 'PRESENT',
      checkInTime,
      checkOutTime,
      workingHours = 8,
      notes,
    } = req.body;

    if (!userId || !date) {
      res.status(400).json({
        success: false,
        message: 'Worker ID and date are required',
      });
      return;
    }

    const targetDate = new Date(String(date));
    const utcDate = new Date(Date.UTC(targetDate.getFullYear(), targetDate.getMonth(), targetDate.getDate()));

    const record = await prisma.attendance.upsert({
      where: {
        userId_date: {
          userId,
          date: utcDate,
        },
      },
      update: {
        status,
        checkInTime: checkInTime ? new Date(checkInTime) : undefined,
        checkOutTime: checkOutTime ? new Date(checkOutTime) : undefined,
        workingHours: Number(workingHours),
        notes,
      },
      create: {
        userId,
        date: utcDate,
        status,
        checkInTime: checkInTime ? new Date(checkInTime) : new Date(),
        checkOutTime: checkOutTime ? new Date(checkOutTime) : undefined,
        workingHours: Number(workingHours),
        notes: notes || 'Manual entry by Admin',
      },
    });

    res.status(200).json({
      success: true,
      message: 'Attendance recorded successfully',
      data: record,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to update attendance',
    });
  }
};

export const getAttendanceSummary = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const today = getTodayDate();

    const [totalActiveWorkers, todayRecords] = await Promise.all([
      prisma.user.count({ where: { role: 'WORKER', status: 'ACTIVE' } }),
      prisma.attendance.findMany({
        where: { date: today },
        include: {
          user: {
            select: { name: true, department: true, designation: true },
          },
        },
      }),
    ]);

    let presentCount = 0;
    let lateCount = 0;
    let halfDayCount = 0;
    let onLeaveCount = 0;

    todayRecords.forEach((r) => {
      if (r.status === 'PRESENT') presentCount++;
      if (r.status === 'LATE') { lateCount++; presentCount++; }
      if (r.status === 'HALF_DAY') halfDayCount++;
      if (r.status === 'ON_LEAVE') onLeaveCount++;
    });

    const absentCount = Math.max(0, totalActiveWorkers - presentCount - onLeaveCount - halfDayCount);

    res.status(200).json({
      success: true,
      data: {
        date: today,
        totalWorkers: totalActiveWorkers,
        present: presentCount,
        late: lateCount,
        halfDay: halfDayCount,
        absent: absentCount,
        onLeave: onLeaveCount,
        attendanceRate: totalActiveWorkers > 0 ? Math.round((presentCount / totalActiveWorkers) * 100) : 0,
        recentCheckIns: todayRecords.slice(0, 10),
      },
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch attendance summary',
    });
  }
};

export const getAttendanceLockStatus = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { date } = req.query;
    let targetDate: Date;
    if (date) {
      const d = new Date(String(date));
      targetDate = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
    } else {
      targetDate = getTodayDate();
    }

    const lock = await prisma.attendanceLock.findUnique({
      where: { date: targetDate },
    });

    res.status(200).json({
      success: true,
      isLocked: lock ? lock.isLocked : false,
      data: lock,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to check lock status',
    });
  }
};

export const toggleAttendanceLock = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { date, isLocked } = req.body;
    let targetDate: Date;
    if (date) {
      const d = new Date(String(date));
      targetDate = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
    } else {
      targetDate = getTodayDate();
    }

    const lockState = isLocked !== undefined ? Boolean(isLocked) : true;

    const lock = await prisma.attendanceLock.upsert({
      where: { date: targetDate },
      update: {
        isLocked: lockState,
        lockedAt: new Date(),
        lockedBy: req.user?.id,
      },
      create: {
        date: targetDate,
        isLocked: lockState,
        lockedAt: new Date(),
        lockedBy: req.user?.id,
      },
    });

    // Also update isLocked on all existing attendance records for that date
    await prisma.attendance.updateMany({
      where: { date: targetDate },
      data: { isLocked: lockState },
    });

    if (lockState) {
      // Broadcast notification
      const activeWorkers = await prisma.user.findMany({
        where: { role: 'WORKER', status: 'ACTIVE' },
        select: { id: true },
      });

      for (const w of activeWorkers) {
        await prisma.notification.create({
          data: {
            userId: w.id,
            title: 'Attendance Locked by Admin (हाजिरी लॉक)',
            message: `Attendance for ${targetDate.toISOString().split('T')[0]} has been locked by Admin.`,
            type: 'ATTENDANCE',
          },
        });
      }
    }

    res.status(200).json({
      success: true,
      message: lockState
        ? 'Attendance locked successfully (हाजिरी लॉक कर दी गई है)'
        : 'Attendance unlocked successfully (हाजिरी अनलॉक कर दी गई है)',
      isLocked: lockState,
      data: lock,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to toggle lock status',
    });
  }
};

