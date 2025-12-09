import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import DatabaseService from './databaseService';
import { User, LoginRequest, LoginResponse } from '../types/database';

class AuthService {
  private db: DatabaseService;
  private jwtSecret: string;

  constructor() {
    this.db = DatabaseService.getInstance();
    this.jwtSecret = process.env.JWT_SECRET || 'dev-secret-key';
  }

  async login(credentials: LoginRequest): Promise<LoginResponse> {
    try {
      // Chercher l'utilisateur par email
      const user = await this.db.findOne('users', { email: credentials.email, is_active: true });
      
      if (!user) {
        return {
          success: false,
          message: 'Email ou mot de passe incorrect'
        };
      }

      // Vérifier le mot de passe
      const isPasswordValid = await bcrypt.compare(credentials.password, user.password_hash);
      
      if (!isPasswordValid) {
        return {
          success: false,
          message: 'Email ou mot de passe incorrect'
        };
      }

      // Générer le clientId pour les clients (basé sur l'email)
      const clientId = user.role === 'client' ? user.email.split('@')[0] : null;

      // Préparer le payload du token
      const payload: any = { 
        userId: user.id, 
        email: user.email, 
        role: user.role
      };

      // Ajouter clientId seulement pour les clients
      if (clientId) {
        payload.clientId = clientId;
      }

      // Générer le token JWT
      const token = jwt.sign(
        payload,
        this.jwtSecret,
        { 
          expiresIn: process.env.JWT_EXPIRES_IN || '24h' 
        } as jwt.SignOptions
      );

      // Log de l'activité
      await this.db.logActivity(user.id, null, 'login', { email: user.email });

      // Retourner le résultat (sans le hash du mot de passe)
      const { password_hash, ...userWithoutPassword } = user;
      
      return {
        success: true,
        data: {
          token,
          user: userWithoutPassword
        }
      };

    } catch (error) {
      console.error('Login error:', error);
      return {
        success: false,
        message: 'Erreur interne du serveur'
      };
    }
  }

  async createUser(email: string, password: string, role: 'admin' | 'client' = 'client'): Promise<User | null> {
    try {
      // Vérifier si l'utilisateur existe déjà
      const existingUser = await this.db.findOne('users', { email });
      if (existingUser) {
        throw new Error('Un utilisateur avec cet email existe déjà');
      }

      // Hasher le mot de passe
      const saltRounds = 12;
      const passwordHash = await bcrypt.hash(password, saltRounds);

      // Créer l'utilisateur
      const newUser = await this.db.insert('users', {
        email,
        password_hash: passwordHash,
        role,
        is_active: true
      });

      return newUser;

    } catch (error) {
      console.error('Create user error:', error);
      throw error;
    }
  }

  async verifyToken(token: string): Promise<any> {
    try {
      const decoded = jwt.verify(token, this.jwtSecret);
      return decoded;
    } catch (error) {
      console.error('Token verification error:', error);
      return null;
    }
  }

  async getUserById(id: number): Promise<Omit<User, 'password_hash'> | null> {
    try {
      const user = await this.db.findOne('users', { id, is_active: true });
      if (!user) return null;

      const { password_hash, ...userWithoutPassword } = user;
      return userWithoutPassword;
    } catch (error) {
      console.error('Get user error:', error);
      return null;
    }
  }

  async updateUserPassword(userId: number, newPassword: string): Promise<boolean> {
    try {
      const saltRounds = 12;
      const passwordHash = await bcrypt.hash(newPassword, saltRounds);

      const updatedUser = await this.db.update('users', userId, {
        password_hash: passwordHash
      });

      if (updatedUser) {
        await this.db.logActivity(userId, null, 'password_change');
        return true;
      }

      return false;
    } catch (error) {
      console.error('Update password error:', error);
      return false;
    }
  }

  // Méthode de fallback pour compatibilité (si la BDD n'est pas disponible)
  async loginFallback(credentials: LoginRequest): Promise<LoginResponse> {
    console.warn('⚠️  Using fallback authentication (hard-coded users)');
    
    const hardcodedUsers = [
      { email: 'admin@portail-cloud.com', password: 'admin123', role: 'admin' }
    ];

    const user = hardcodedUsers.find(u => 
      u.email === credentials.email && u.password === credentials.password
    );

    if (!user) {
      return {
        success: false,
        message: 'Email ou mot de passe incorrect'
      };
    }

    const token = jwt.sign(
      { userId: 1, email: user.email, role: user.role },
      this.jwtSecret,
      { expiresIn: '24h' }
    );

    return {
      success: true,
      data: {
        token,
        user: {
          id: 1,
          email: user.email,
          role: user.role as 'admin' | 'client',
          created_at: new Date(),
          updated_at: new Date(),
          is_active: true
        }
      }
    };
  }
}

export default AuthService;