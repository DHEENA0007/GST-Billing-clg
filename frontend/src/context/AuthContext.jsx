import React, { createContext, useState, useEffect } from 'react';
import axios from 'axios';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
    const [user, setUser] = useState(null);
    const [token, setToken] = useState(localStorage.getItem('access_token'));
    const [isLoading, setIsLoading] = useState(true);

    const API_URL = '/api/auth';

    useEffect(() => {
        if (token) {
            loadUserProfile(token);
        } else {
            setIsLoading(false);
        }
    }, [token]);

    const loadUserProfile = async (token) => {
        try {
            const response = await axios.get(`${API_URL}/profile/`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setUser(response.data);
        } catch (error) {
            console.error("Failed to load profile", error);
            logout();
        } finally {
            setIsLoading(false);
        }
    };

    const login = async (username, password) => {
        try {
            setIsLoading(true);
            const response = await axios.post(`${API_URL}/login/`, { username, password });
            const { access, refresh } = response.data;
            localStorage.setItem('access_token', access);
            localStorage.setItem('refresh_token', refresh);
            setToken(access);
            // user profile will be loaded by useEffect
            return { success: true };
        } catch (error) {
            setIsLoading(false);
            return { success: false, message: error.response?.data?.detail || 'Login failed' };
        }
    };

    const register = async (userData) => {
        try {
            setIsLoading(true);
            await axios.post(`${API_URL}/register/`, userData);
            // Auto login after register
            return await login(userData.username, userData.password);
        } catch (error) {
            setIsLoading(false);
            let errorMsg = 'Registration failed';
            if (error.response?.data) {
                // Collect first error message if validation failed
                const keys = Object.keys(error.response.data);
                if (keys.length > 0) {
                    errorMsg = error.response.data[keys[0]][0];
                }
            }
            return { success: false, message: errorMsg };
        }
    };

    const logout = () => {
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        setToken(null);
        setUser(null);
    };

    return (
        <AuthContext.Provider value={{ user, token, login, register, logout, isLoading }}>
            {children}
        </AuthContext.Provider>
    );
};

export default AuthContext;
