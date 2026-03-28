import pygame
import random
import sys

# Constants
CELL_SIZE = 20
COLS = 30
ROWS = 30
WIDTH = COLS * CELL_SIZE
HEIGHT = ROWS * CELL_SIZE
FPS_BASE = 8

# Colors
BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
GREEN = (0, 200, 80)
DARK_GREEN = (0, 150, 50)
RED = (220, 50, 50)
GRAY = (40, 40, 40)
YELLOW = (255, 220, 0)


class Snake:
    def __init__(self):
        self.body = [(COLS // 2, ROWS // 2)]
        self.direction = (1, 0)
        self.grow_next = False

    def set_direction(self, dx, dy):
        # Prevent reversing
        if (dx, dy) != (-self.direction[0], -self.direction[1]):
            self.direction = (dx, dy)

    def move(self):
        head = self.body[0]
        new_head = (head[0] + self.direction[0], head[1] + self.direction[1])
        self.body.insert(0, new_head)
        if self.grow_next:
            self.grow_next = False
        else:
            self.body.pop()

    def grow(self):
        self.grow_next = True

    def head(self):
        return self.body[0]

    def check_wall_collision(self):
        hx, hy = self.head()
        return hx < 0 or hx >= COLS or hy < 0 or hy >= ROWS

    def check_self_collision(self):
        return self.head() in self.body[1:]


class Food:
    def __init__(self, snake_body):
        self.position = self._random_pos(snake_body)

    def _random_pos(self, snake_body):
        while True:
            pos = (random.randint(0, COLS - 1), random.randint(0, ROWS - 1))
            if pos not in snake_body:
                return pos

    def respawn(self, snake_body):
        self.position = self._random_pos(snake_body)


class Game:
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((WIDTH, HEIGHT))
        pygame.display.set_caption("貪吃蛇 Snake")
        self.clock = pygame.time.Clock()
        self.font_large = pygame.font.SysFont("Arial", 48, bold=True)
        self.font_small = pygame.font.SysFont("Arial", 24)
        self.reset()

    def reset(self):
        self.snake = Snake()
        self.food = Food(self.snake.body)
        self.score = 0
        self.game_over = False

    def handle_events(self):
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if self.game_over:
                    if event.key == pygame.K_r:
                        self.reset()
                    elif event.key == pygame.K_ESCAPE:
                        pygame.quit()
                        sys.exit()
                else:
                    if event.key == pygame.K_UP or event.key == pygame.K_w:
                        self.snake.set_direction(0, -1)
                    elif event.key == pygame.K_DOWN or event.key == pygame.K_s:
                        self.snake.set_direction(0, 1)
                    elif event.key == pygame.K_LEFT or event.key == pygame.K_a:
                        self.snake.set_direction(-1, 0)
                    elif event.key == pygame.K_RIGHT or event.key == pygame.K_d:
                        self.snake.set_direction(1, 0)

    def update(self):
        if self.game_over:
            return

        self.snake.move()

        if self.snake.check_wall_collision() or self.snake.check_self_collision():
            self.game_over = True
            return

        if self.snake.head() == self.food.position:
            self.snake.grow()
            self.score += 10
            self.food.respawn(self.snake.body)

    def draw_grid(self):
        for x in range(0, WIDTH, CELL_SIZE):
            pygame.draw.line(self.screen, GRAY, (x, 0), (x, HEIGHT))
        for y in range(0, HEIGHT, CELL_SIZE):
            pygame.draw.line(self.screen, GRAY, (0, y), (WIDTH, y))

    def draw(self):
        self.screen.fill(BLACK)
        self.draw_grid()

        # Draw food
        fx, fy = self.food.position
        food_rect = pygame.Rect(fx * CELL_SIZE + 2, fy * CELL_SIZE + 2, CELL_SIZE - 4, CELL_SIZE - 4)
        pygame.draw.ellipse(self.screen, RED, food_rect)

        # Draw snake
        for i, (bx, by) in enumerate(self.snake.body):
            color = GREEN if i == 0 else DARK_GREEN
            rect = pygame.Rect(bx * CELL_SIZE + 1, by * CELL_SIZE + 1, CELL_SIZE - 2, CELL_SIZE - 2)
            pygame.draw.rect(self.screen, color, rect, border_radius=4)

        # Score
        score_surf = self.font_small.render(f"Score: {self.score}", True, WHITE)
        self.screen.blit(score_surf, (8, 8))

        if self.game_over:
            self._draw_game_over()

        pygame.display.flip()

    def _draw_game_over(self):
        overlay = pygame.Surface((WIDTH, HEIGHT), pygame.SRCALPHA)
        overlay.fill((0, 0, 0, 160))
        self.screen.blit(overlay, (0, 0))

        title = self.font_large.render("Game Over", True, RED)
        score_text = self.font_small.render(f"Final Score: {self.score}", True, YELLOW)
        restart_text = self.font_small.render("Press R to restart  |  ESC to quit", True, WHITE)

        self.screen.blit(title, title.get_rect(center=(WIDTH // 2, HEIGHT // 2 - 50)))
        self.screen.blit(score_text, score_text.get_rect(center=(WIDTH // 2, HEIGHT // 2 + 10)))
        self.screen.blit(restart_text, restart_text.get_rect(center=(WIDTH // 2, HEIGHT // 2 + 50)))

    def run(self):
        while True:
            self.handle_events()
            self.update()
            self.draw()
            # Speed increases with score
            fps = FPS_BASE + self.score // 50
            self.clock.tick(fps)


if __name__ == "__main__":
    game = Game()
    game.run()
