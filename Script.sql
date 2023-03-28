-- Criação da tabela de Categorias
CREATE TABLE Categorias (
	id SERIAL PRIMARY KEY,
	nome VARCHAR(50) NOT NULL
);

-- Criação da tabela de Produtos e relacionamento com Categorias
CREATE TABLE Produtos (
	id SERIAL PRIMARY KEY,
	nome VARCHAR(100) NOT NULL,
	descricao TEXT,
	preco NUMERIC(10, 2) NOT NULL,
	categoria_id INTEGER not NULL,
	FOREIGN KEY (categoria_id) REFERENCES Categorias(id)
);

-- Criação da tabela de Clientes
CREATE TABLE Clientes (
	id SERIAL PRIMARY KEY,
	nome VARCHAR(100) NOT NULL,
	email VARCHAR(100) UNIQUE
);

-- Criação da tabela de Pedidos e relacionamento com Cliente
CREATE TABLE Pedidos (
	id SERIAL PRIMARY KEY,
	data TIMESTAMP NOT NULL,
	cliente_id INTEGER NOT NULL,
	endereco_entrega VARCHAR(100) NOT NULL,
	FOREIGN KEY (cliente_id) REFERENCES Clientes(id)
);

-- Criação da tabela ItensPedido e relacionamentos com Produto e Pedido
CREATE TABLE Itens_pedido (
	pedido_id INTEGER NOT NULL,
	produto_id INTEGER NOT NULL,
	quantidade INTEGER NOT NULL,
	FOREIGN KEY (pedido_id) REFERENCES Pedidos(id),
	FOREIGN KEY (produto_id) REFERENCES Produtos(id),
	PRIMARY KEY (pedido_id, produto_id)
);


CREATE OR REPLACE PROCEDURE PopularCategorias (
	Qnt	INTEGER
)
LANGUAGE SQL 
AS $$
	-- Inserindo dados de Categorias
	INSERT INTO Categorias (nome)
	SELECT 'Categoria' || i
	FROM generate_series(1, Qnt) AS i;
$$;

CALL POPULARCATEGORIAS(50)

CREATE OR REPLACE PROCEDURE PopularProdutos (
	Qnt INTEGER
)
LANGUAGE SQL 
AS $$
	-- Inserindo dados de Produtos
	INSERT INTO Produtos (nome, descricao, preco, categoria_id)
	SELECT 'Produto' || i, 
		   'Descriçao produto' || i, 
		   (i + 0.99)::decimal(10, 2), 
		   (i % Qnt) + 1
	FROM generate_series(1, Qnt) AS i;
$$;

CALL POPULARPRODUTOS(50)

CREATE OR REPLACE PROCEDURE PopularClientes (
	Qnt INTEGER
)
LANGUAGE SQL 
AS $$
	-- Inserindo dados de Clientes
	INSERT INTO Clientes (nome, email)
	SELECT 'Cliente' || i, 'cliente' || i || '@email.com'
	FROM generate_series(1, Qnt) AS i;
$$;	

CALL POPULARCLIENTES(50)

CREATE OR REPLACE PROCEDURE PopularPedidos (
	Qnt INTEGER
)
LANGUAGE SQL 
AS $$
	-- Inserindo dados de Pedidos
	INSERT INTO Pedidos (data, endereco_entrega, cliente_id)
	SELECT now() - (i * interval '1 hour'), 'Endereco' || i, (i % Qnt) + 1
	FROM generate_series(1, Qnt) AS i;
$$;

CALL POPULARPEDIDOS(50)

CREATE OR REPLACE PROCEDURE PopularItens_pedido (
	Qnt 		   INTEGER,
	QntItensPedido INTEGER
)
LANGUAGE SQL 
AS $$
	-- Inserindo dados de Itens_pedido
	INSERT INTO Itens_pedido (pedido_id, produto_id, quantidade)
	SELECT (i % @Qnt) + 1, (i % (Qnt - QntItensPedido)) + p, (i % 5) + 1
	FROM generate_series(1, Qnt) AS i,
		 generate_series(1, QntItensPedido) AS p;
$$;

CALL POPULARITENS_PEDIDO(50, 3)


-- Listar todos os produtos por ordem alfabética crescente
SELECT
	p.id,
	p.nome, 
	p.descricao, 
	p.preco
FROM Produtos AS p
ORDER BY p.nome ASC

-- Listar todas as categorias em ordem alfabética crescente
SELECT
	c.id,
	c.nome, 
	COUNT(p.id) AS qnt_produtos
FROM Categorias AS c
	LEFT JOIN Produtos AS p ON (p.categoria_id = c.id)
GROUP BY 
	c.id,
	c.nome
ORDER BY c.nome

-- Listar todos os pedidos em ordem decrescente de data
SELECT
	ped.id,
	ped.data,
	ped.endereco_entrega,
	SUM(pro.preco * ip.quantidade) AS total
FROM Itens_pedido AS ip
	INNER JOIN Pedidos AS ped ON (ip.pedido_id = ped.id)
	INNER JOIN Produtos AS pro ON (ip.produto_id = pro.id)
GROUP BY
	ped.id,
	ped.data,
	ped.endereco_entrega
	
-- Listar todos os produtos vendidos em ordem decrescente de quantidade vendida
SELECT
	p.id,
	p.nome,
	p.descricao,
	p.preco,
	SUM(ip.quantidade) AS quantidade_total
FROM Itens_pedido ip
INNER JOIN Produtos AS p ON (p.id = ip.produto_id)
GROUP BY
	p.id
ORDER BY quantidade_total DESC

-- Listar todos os pedidos de um determinado cliente em um período e em ordem 
SELECT
	c.id AS id_cliente,
	c.nome AS nome_cliente,
	c.email AS email_cliente,
	p.id AS id_pedido,
	p.data,
	p.endereco_entrega
FROM Clientes c
INNER JOIN Pedidos AS p ON (p.cliente_id = c.id)
WHERE
	'2023-03-25' <= p.data AND p.data <= '2023-03-29' 
ORDER BY c.nome ASC, 
	p.DATA ASC
	
-- Listar possíveis produtos repetidos por nome e quantidade de replicações
SELECT 
	p.nome,
	(COUNT(*) - 1) AS replicacoes
FROM Produtos p
GROUP BY p.nome
HAVING COUNT(*) > 1
ORDER BY replicacoes DESC



