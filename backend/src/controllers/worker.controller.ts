import { Response } from 'express';
import bcrypt from 'bcryptjs';
import { prisma } from '../prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export const getAllWorkers = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { search, department, status, role } = req.query;

    const where: any = {};

    if (search) {
      const q = String(search).trim();
      where.OR = [
        { name: { contains: q, mode: 'insensitive' } },
        { email: { contains: q, mode: 'insensitive' } },
        { phone: { contains: q } },
        { designation: { contains: q, mode: 'insensitive' } },
      ];
    }

    if (department && department !== 'ALL') {
      where.department = String(department);
    }

    if (status && status !== 'ALL') {
      where.status = String(status);
    }

    if (role) {
      where.role = String(role);
    }

    const workers = await prisma.user.findMany({
      where,
      select: {
        id: true,
        name: true,
        email: true,
        phone: true,
        role: true,
        department: true,
        designation: true,
        monthlySalary: true,
        hourlyRate: true,
        status: true,
        avatarUrl: true,
        address: true,
        emergencyContact: true,
        bankAccount: true,
        upiId: true,
        aadhaarNumber: true,
        aadhaarFrontUrl: true,
        aadhaarBackUrl: true,
        dateOfJoining: true,
        createdAt: true,
        _count: {
          select: {
            assignedTasks: true,
            attendances: true,
            leaves: true,
          },
        },
      },
      orderBy: { name: 'asc' },
    });

    res.status(200).json({
      success: true,
      count: workers.length,
      data: workers,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch workers',
    });
  }
};

export const getWorkerById = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    const worker = await prisma.user.findUnique({
      where: { id: id as string },
      include: {
        attendances: {
          take: 7,
          orderBy: { date: 'desc' },
        },
        assignedTasks: {
          take: 5,
          orderBy: { createdAt: 'desc' },
        },
        leaves: {
          take: 5,
          orderBy: { createdAt: 'desc' },
        },
        salaryRecords: {
          take: 3,
          orderBy: { year: 'desc' },
        },
        expenses: {
          take: 5,
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!worker) {
      res.status(404).json({
        success: false,
        message: 'Worker not found',
      });
      return;
    }

    const { password: _, ...workerData } = worker;

    res.status(200).json({
      success: true,
      data: workerData,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch worker details',
    });
  }
};

export const createWorker = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const {
      name,
      email,
      phone,
      password = 'password123',
      role = 'WORKER',
      department = 'General',
      designation = 'Worker',
      monthlySalary = 20000,
      hourlyRate = 100,
      address,
      emergencyContact,
      bankAccount,
      upiId,
      aadhaarNumber,
      aadhaarFrontUrl,
      aadhaarBackUrl,
      dateOfJoining,
    } = req.body;

    if (!name || !phone) {
      res.status(400).json({
        success: false,
        message: 'Name and phone number are required',
      });
      return;
    }

    const workerEmail = (email && email.trim().length > 0)
        ? email.trim().toLowerCase()
        : `${phone.trim()}@worker.local`;

    const existing = await prisma.user.findFirst({
      where: {
        OR: [
          { email: workerEmail },
          { phone: phone.trim() },
        ],
      },
    });

    if (existing) {
      res.status(409).json({
        success: false,
        message: 'Worker with this phone number already exists',
      });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const hashedPassword = await bcrypt.hash(password, salt);

    const worker = await prisma.user.create({
      data: {
        name: name.trim(),
        email: workerEmail,
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
        aadhaarNumber,
        aadhaarFrontUrl,
        aadhaarBackUrl,
        dateOfJoining: dateOfJoining ? new Date(dateOfJoining) : new Date(),
      },
    });

    // Create a welcome notification
    await prisma.notification.create({
      data: {
        userId: worker.id,
        title: 'Welcome to the Team!',
        message: `Hello ${worker.name}, your worker account has been created. You can now log in and record attendance.`,
        type: 'SYSTEM',
      },
    });

    const { password: _, ...workerData } = worker;

    res.status(201).json({
      success: true,
      message: 'Worker created successfully',
      data: workerData,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to create worker',
    });
  }
};

export const updateWorker = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;
    const {
      name,
      email,
      phone,
      role,
      department,
      designation,
      monthlySalary,
      hourlyRate,
      status,
      address,
      emergencyContact,
      bankAccount,
      upiId,
      aadhaarNumber,
      aadhaarFrontUrl,
      aadhaarBackUrl,
      dateOfJoining,
      password,
    } = req.body;

    const data: any = {};
    if (name) data.name = name.trim();
    if (email) data.email = email.trim().toLowerCase();
    if (phone) data.phone = phone.trim();
    if (role) data.role = role;
    if (department) data.department = department;
    if (designation) data.designation = designation;
    if (monthlySalary !== undefined) data.monthlySalary = Number(monthlySalary);
    if (hourlyRate !== undefined) data.hourlyRate = Number(hourlyRate);
    if (status) data.status = status;
    if (address !== undefined) data.address = address;
    if (emergencyContact !== undefined) data.emergencyContact = emergencyContact;
    if (bankAccount !== undefined) data.bankAccount = bankAccount;
    if (upiId !== undefined) data.upiId = upiId;
    if (aadhaarNumber !== undefined) data.aadhaarNumber = aadhaarNumber;
    if (aadhaarFrontUrl !== undefined) data.aadhaarFrontUrl = aadhaarFrontUrl;
    if (aadhaarBackUrl !== undefined) data.aadhaarBackUrl = aadhaarBackUrl;
    if (dateOfJoining) data.dateOfJoining = new Date(dateOfJoining);

    if (password) {
      const salt = await bcrypt.genSalt(10);
      data.password = await bcrypt.hash(password, salt);
    }

    const updated = await prisma.user.update({
      where: { id: id as string },
      data,
    });

    const { password: _, ...workerData } = updated;

    res.status(200).json({
      success: true,
      message: 'Worker updated successfully',
      data: workerData,
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to update worker',
    });
  }
};

export const deleteWorker = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const { id } = req.params;

    // Soft delete or hard delete
    await prisma.user.delete({
      where: { id: id as string },
    });

    res.status(200).json({
      success: true,
      message: 'Worker deleted successfully',
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to delete worker',
    });
  }
};

export const getDepartments = async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const departments = await prisma.user.findMany({
      select: { department: true },
      distinct: ['department'],
    });

    const list = departments.map((d) => d.department).filter(Boolean);

    res.status(200).json({
      success: true,
      data: list.length > 0 ? list : ['Construction', 'Logistics', 'Electrical', 'Maintenance', 'Plumbing', 'Office'],
    });
  } catch (error: any) {
    res.status(500).json({
      success: false,
      message: error.message || 'Failed to fetch departments',
    });
  }
};
