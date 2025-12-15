INSERT INTO FactoryArea (FactoryCode, Name, Location)
VALUES
('A01', '城南工业园主厂区', '市南区科技园路88号'),
('A02', '城北新能源分厂', '市北区工业北路156号'),
('A03', '东郊光伏产业园', '市东区光伏路23号'),
('A04', '西郊综合能源基地', '市西区能源大道59号'),
('A05', '滨海化工园区', '滨海新区化工路77号'),
('A06', '高新技术产业园', '高新区创新路34号'),
('A07', '空港经济区工厂', '空港经济区启航路12号'),
('A08', '临港工业园分厂', '临港新区海港路45号'),
('A09', '生态城示范工厂', '生态城绿色路68号'),
('A10', '老城区改造工厂', '老城区复古路29号'),
('B01', '省会城市总部工厂', '省会市高新区总部大道1号'),
('B02', '二线城市生产基地', '二线市经开区生产路8号'),
('B03', '三线城市配套工厂', '三线市工业区配套路16号'),
('B04', '四线城市加工分厂', '四线市工业园加工路22号'),
('B05', '五线城市组装工厂', '五线市产业区组装路33号'),
('C01', '东部沿海工厂', '东部市沿海路56号'),
('C02', '西部内陆工厂', '西部市内陆路78号'),
('C03', '南部丘陵工厂', '南部市丘陵路41号'),
('C04', '北部平原工厂', '北部市平原路92号'),
('C05', '中部枢纽工厂', '中部市枢纽路63号');

--系统管理员            Admin
--能源管理员            EnergyAdmin
--运维人员             Maintainer
--数据分析师            Analyst
--企业管理层            Manager
--运维工单管理员         WorkOrderAdmin

INSERT INTO UserAccount (UserName, RealName, PasswordHash, Phone, RoleCode, IsLocked, FailedLoginCount)
VALUES
('admin01', '张管理员', HASHBYTES('SHA2_256', '123456'), '13800138001', 'Admin', 0, 0),
('admin02', '尤管理员', HASHBYTES('SHA2_256', '123456'), '13800138020', 'Admin', 0, 0),
('energy01', '李能源管理员', HASHBYTES('SHA2_256', '123456'), '13800138002', 'EnergyAdmin', 0, 0),
('energy02', '王能源管理员', HASHBYTES('SHA2_256', '123456'), '13800138003', 'EnergyAdmin', 0, 1),
('energy03', '朱能源管理员', HASHBYTES('SHA2_256', '123456'), '13800138018', 'EnergyAdmin', 0, 0),
('maintain01', '赵运维', HASHBYTES('SHA2_256', '123456'), '13800138004', 'Maintainer', 0, 0),
('maintain02', '孙运维', HASHBYTES('SHA2_256', '123456'), '13800138005', 'Maintainer', 0, 2),
('maintain03', '周运维', HASHBYTES('SHA2_256', '123456'), '13800138006', 'Maintainer', 1, 5),
('maintain04', '吴运维', HASHBYTES('SHA2_256', '123456'), '13800138007', 'Maintainer', 0, 0),
('maintain05', '郑运维', HASHBYTES('SHA2_256', '123456'), '13800138008', 'Maintainer', 0, 0),
('maintain06', '卫运维', HASHBYTES('SHA2_256', '123456'), '13800138013', 'Maintainer', 0, 0),
('maintain07', '蒋运维', HASHBYTES('SHA2_256', '123456'), '13800138014', 'Maintainer', 0, 0),
('maintain08', '沈运维', HASHBYTES('SHA2_256', '123456'), '13800138015', 'Maintainer', 0, 3),
('analyst01', '钱分析师', HASHBYTES('SHA2_256', '123456'), '13800138009', 'Analyst', 0, 0),
('analyst02', '冯分析师', HASHBYTES('SHA2_256', '123456'), '13800138010', 'Analyst', 0, 0),
('analyst03', '秦分析师', HASHBYTES('SHA2_256', '123456'), '13800138019', 'Analyst', 0, 0),
('manager01', '陈经理', HASHBYTES('SHA2_256', '123456'), '13800138011', 'Manager', 0, 0),
('manager02', '褚经理', HASHBYTES('SHA2_256', '123456'), '13800138012', 'Manager', 0, 0),
('workorderadmin01', '韩运维工单管理员', HASHBYTES('SHA2_256', '123456'), '13800138016', 'WorkOrderAdmin', 0, 0),
('workorderadmin02', '杨运维工单管理员', HASHBYTES('SHA2_256', '123456'), '13800138017', 'WorkOrderAdmin', 0, 0);



