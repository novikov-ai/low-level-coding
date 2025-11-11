// ARM64 version for Apple Silicon Macs

.section __TEXT,__text
.globl _main
.align 2

// =============================================
// Main program entry point
// =============================================
_main:
    stp    x29, x30, [sp, #-16]!   // Save frame pointer and link register
    mov    x29, sp                  // Set up frame pointer
    
    bl     _init_random             // Initialize random seed
    
game_loop:
    // Reset game state
    adrp   x0, game_won@PAGE
    add    x0, x0, game_won@PAGEOFF
    str    xzr, [x0]                // game_won = 0
    
    adrp   x0, current_score@PAGE
    add    x0, x0, current_score@PAGEOFF
    mov    x1, #1000
    str    x1, [x0]                 // current_score = 1000
    
    // Display welcome message
    adrp   x0, welcome_msg@PAGE
    add    x0, x0, welcome_msg@PAGEOFF
    bl     _print_string
    
    // Display menu and get difficulty choice
    bl     _show_menu
    
    // Check if user chose to exit
    adrp   x0, input_buffer@PAGE
    add    x0, x0, input_buffer@PAGEOFF
    ldrb   w1, [x0]
    cmp    w1, #'4'
    b.eq   1f                       // Local label for game_exit
    
    // Validate menu choice
    cmp    w1, #'1'
    b.lo   2f                       // Local label for invalid_menu
    cmp    w1, #'3'
    b.hi   2f                       // Local label for invalid_menu
    
    // Setup game based on difficulty
    bl     _setup_game
    
    // Play the game
    bl     _play_game
    
    // Ask to play again
    bl     _ask_play_again
    adrp   x0, input_buffer@PAGE
    add    x0, x0, input_buffer@PAGEOFF
    ldrb   w1, [x0]
    cmp    w1, #'y'
    b.eq   game_loop
    cmp    w1, #'Y'
    b.eq   game_loop
    
    b      game_loop

1:  // game_exit
    // Exit message
    adrp   x0, newline@PAGE
    add    x0, x0, newline@PAGEOFF
    bl     _print_string
    
    mov    x0, #0                   // Exit status 0
    mov    x16, #1                  // exit system call
    svc    #0x80

2:  // invalid_menu
    adrp   x0, invalid_choice_msg@PAGE
    add    x0, x0, invalid_choice_msg@PAGEOFF
    bl     _print_string
    b      game_loop

// =============================================
// Show main menu and get user choice
// =============================================
_show_menu:
    stp    x29, x30, [sp, #-16]!
    mov    x29, sp
    
0:  // menu_retry
    adrp   x0, menu_msg@PAGE
    add    x0, x0, menu_msg@PAGEOFF
    bl     _print_string
    
    bl     _read_input
    
    // Validate input length
    adrp   x0, input_len@PAGE
    add    x0, x0, input_len@PAGEOFF
    ldr    x1, [x0]
    cmp    x1, #1
    b.ne   1f                       // Local label for menu_invalid
    
    adrp   x0, input_buffer@PAGE
    add    x0, x0, input_buffer@PAGEOFF
    ldrb   w1, [x0]
    cmp    w1, #'1'
    b.lo   1f                       // Local label for menu_invalid
    cmp    w1, #'4'
    b.hi   1f                       // Local label for menu_invalid
    
    b      2f                       // Local label for menu_done
    
1:  // menu_invalid
    adrp   x0, invalid_choice_msg@PAGE
    add    x0, x0, invalid_choice_msg@PAGEOFF
    bl     _print_string
    b      0b                       // Back to menu_retry
    
2:  // menu_done
    ldp    x29, x30, [sp], #16
    ret

// =============================================
// Setup game parameters based on difficulty
// =============================================
_setup_game:
    stp    x29, x30, [sp, #-16]!
    mov    x29, sp
    
    adrp   x0, input_buffer@PAGE
    add    x0, x0, input_buffer@PAGEOFF
    ldrb   w1, [x0]
    
    cmp    w1, #'1'
    b.eq   0f                       // Local label for easy
    cmp    w1, #'2'  
    b.eq   1f                       // Local label for medium
    cmp    w1, #'3'
    b.eq   2f                       // Local label for hard
    
    b      3f                       // Local label for setup_store
    
0:  // setup_easy
    mov    x0, #10
    b      3f
    
1:  // setup_medium
    mov    x0, #50
    b      3f
    
2:  // setup_hard
    mov    x0, #100
    
3:  // setup_store
    // Store max_range
    adrp   x1, max_range@PAGE
    add    x1, x1, max_range@PAGEOFF
    str    x0, [x1]
    
    // Set attempts based on difficulty
    adrp   x0, input_buffer@PAGE
    add    x0, x0, input_buffer@PAGEOFF
    ldrb   w1, [x0]
    
    cmp    w1, #'1'
    b.eq   4f                       // Local label for easy attempts
    cmp    w1, #'2'
    b.eq   5f                       // Local label for medium attempts
    
    // Hard: 5 attempts
    mov    x0, #5
    b      6f                       // Local label for attempts_store
    
4:  // setup_attempts_easy
    // Easy: 10 attempts
    mov    x0, #10
    b      6f
    
5:  // setup_attempts_medium
    // Medium: 7 attempts
    mov    x0, #7
    
6:  // setup_attempts_store
    adrp   x1, max_attempts@PAGE
    add    x1, x1, max_attempts@PAGEOFF
    str    x0, [x1]
    
    adrp   x1, attempts_left@PAGE
    add    x1, x1, attempts_left@PAGEOFF
    str    x0, [x1]
    
    // Generate random number
    adrp   x0, max_range@PAGE
    add    x0, x0, max_range@PAGEOFF
    ldr    x0, [x0]
    bl     _generate_random
    
    adrp   x1, target_number@PAGE
    add    x1, x1, target_number@PAGEOFF
    str    x0, [x1]
    
    // Display game info
    adrp   x0, range_msg@PAGE
    add    x0, x0, range_msg@PAGEOFF
    bl     _print_string
    
    adrp   x0, max_range@PAGE
    add    x0, x0, max_range@PAGEOFF
    ldr    x0, [x0]
    bl     _print_number
    
    adrp   x0, newline@PAGE
    add    x0, x0, newline@PAGEOFF
    bl     _print_string
    
    ldp    x29, x30, [sp], #16
    ret

// =============================================
// Main game loop
// =============================================
_play_game:
    stp    x29, x30, [sp, #-16]!
    mov    x29, sp
    
0:  // game_round
    // Check if attempts exhausted
    adrp   x0, attempts_left@PAGE
    add    x0, x0, attempts_left@PAGEOFF
    ldr    x1, [x0]
    cmp    x1, #0
    b.le   1f                       // Local label for game_lost
    
    // Display attempts remaining
    adrp   x0, attempts_msg@PAGE
    add    x0, x0, attempts_msg@PAGEOFF
    bl     _print_string
    
    adrp   x0, attempts_left@PAGE
    add    x0, x0, attempts_left@PAGEOFF
    ldr    x0, [x0]
    bl     _print_number
    
    adrp   x0, newline@PAGE
    add    x0, x0, newline@PAGEOFF
    bl     _print_string
    
    // Get user guess
    adrp   x0, prompt_msg@PAGE
    add    x0, x0, prompt_msg@PAGEOFF
    bl     _print_string
    
    bl     _read_input
    bl     _parse_input
    
    // Validate input
    cmp    x0, #0
    b.le   2f                       // Local label for invalid_input
    
    adrp   x1, max_range@PAGE
    add    x1, x1, max_range@PAGEOFF
    ldr    x1, [x1]
    cmp    x0, x1
    b.gt   2f                       // Local label for invalid_input
    
    // Valid input, process guess
    mov    x19, x0                  // Save guess in x19
    
    // Decrement attempts
    adrp   x0, attempts_left@PAGE
    add    x0, x0, attempts_left@PAGEOFF
    ldr    x1, [x0]
    sub    x1, x1, #1
    str    x1, [x0]
    
    // Check guess against target
    adrp   x0, target_number@PAGE
    add    x0, x0, target_number@PAGEOFF
    ldr    x1, [x0]
    cmp    x19, x1
    b.eq   3f                       // Local label for game_won
    b.gt   4f                       // Local label for guess_too_high
    b.lt   5f                       // Local label for guess_too_low
    
2:  // invalid_input
    adrp   x0, invalid_choice_msg@PAGE
    add    x0, x0, invalid_choice_msg@PAGEOFF
    bl     _print_string
    b      0b                       // Back to game_round
    
4:  // guess_too_high
    adrp   x0, too_high_msg@PAGE
    add    x0, x0, too_high_msg@PAGEOFF
    bl     _print_string
    
    // Update score
    adrp   x0, attempts_left@PAGE
    add    x0, x0, attempts_left@PAGEOFF
    ldr    x1, [x0]
    mov    x2, #10
    mul    x1, x1, x2
    
    adrp   x0, current_score@PAGE
    add    x0, x0, current_score@PAGEOFF
    ldr    x2, [x0]
    sub    x2, x2, x1
    str    x2, [x0]
    
    b      0b                       // Back to game_round
    
5:  // guess_too_low
    adrp   x0, too_low_msg@PAGE
    add    x0, x0, too_low_msg@PAGEOFF
    bl     _print_string
    
    // Update score
    adrp   x0, attempts_left@PAGE
    add    x0, x0, attempts_left@PAGEOFF
    ldr    x1, [x0]
    mov    x2, #10
    mul    x1, x1, x2
    
    adrp   x0, current_score@PAGE
    add    x0, x0, current_score@PAGEOFF
    ldr    x2, [x0]
    sub    x2, x2, x1
    str    x2, [x0]
    
    b      0b                       // Back to game_round
    
3:  // game_won
    adrp   x0, game_won@PAGE
    add    x0, x0, game_won@PAGEOFF
    mov    x1, #1
    str    x1, [x0]
    
    adrp   x0, win_msg@PAGE
    add    x0, x0, win_msg@PAGEOFF
    bl     _print_string
    
    // Bonus points for remaining attempts
    adrp   x0, attempts_left@PAGE
    add    x0, x0, attempts_left@PAGEOFF
    ldr    x1, [x0]
    mov    x2, #100
    mul    x1, x1, x2
    
    adrp   x0, current_score@PAGE
    add    x0, x0, current_score@PAGEOFF
    ldr    x2, [x0]
    add    x2, x2, x1
    str    x2, [x0]
    
    b      6f                       // Local label for game_end
    
1:  // game_lost
    adrp   x0, lose_msg@PAGE
    add    x0, x0, lose_msg@PAGEOFF
    bl     _print_string
    
6:  // game_end
    // Reveal the number
    adrp   x0, reveal_msg@PAGE
    add    x0, x0, reveal_msg@PAGEOFF
    bl     _print_string
    
    adrp   x0, target_number@PAGE
    add    x0, x0, target_number@PAGEOFF
    ldr    x0, [x0]
    bl     _print_number
    
    adrp   x0, newline@PAGE
    add    x0, x0, newline@PAGEOFF
    bl     _print_string
    
    // Display final score
    adrp   x0, score_msg@PAGE
    add    x0, x0, score_msg@PAGEOFF
    bl     _print_string
    
    adrp   x0, current_score@PAGE
    add    x0, x0, current_score@PAGEOFF
    ldr    x0, [x0]
    bl     _print_number
    
    adrp   x0, newline@PAGE
    add    x0, x0, newline@PAGEOFF
    bl     _print_string
    
    ldp    x29, x30, [sp], #16
    ret

// =============================================
// Ask user if they want to play again
// =============================================
_ask_play_again:
    stp    x29, x30, [sp, #-16]!
    mov    x29, sp
    
0:  // play_again_retry
    adrp   x0, play_again_msg@PAGE
    add    x0, x0, play_again_msg@PAGEOFF
    bl     _print_string
    
    bl     _read_input
    
    // Validate input
    adrp   x0, input_len@PAGE
    add    x0, x0, input_len@PAGEOFF
    ldr    x1, [x0]
    cmp    x1, #1
    b.ne   1f                       // Local label for play_again_invalid
    
    adrp   x0, input_buffer@PAGE
    add    x0, x0, input_buffer@PAGEOFF
    ldrb   w1, [x0]
    cmp    w1, #'y'
    b.eq   2f                       // Local label for play_again_done
    cmp    w1, #'Y'
    b.eq   2f                       // Local label for play_again_done
    cmp    w1, #'n'
    b.eq   2f                       // Local label for play_again_done
    cmp    w1, #'N'
    b.eq   2f                       // Local label for play_again_done
    
1:  // play_again_invalid
    adrp   x0, invalid_choice_msg@PAGE
    add    x0, x0, invalid_choice_msg@PAGEOFF
    bl     _print_string
    b      0b                       // Back to play_again_retry
    
2:  // play_again_done
    ldp    x29, x30, [sp], #16
    ret

// =============================================
// Initialize random number generator
// =============================================
_init_random:
    stp    x29, x30, [sp, #-32]!
    mov    x29, sp
    
    // Get current time for seed
    mov    x0, #0                    // NULL for time
    bl     _time
    and    x0, x0, #0x7FFFFFFF       // Get positive value
    
    adrp   x1, _random_seed@PAGE
    add    x1, x1, _random_seed@PAGEOFF
    str    w0, [x1]                  // Store as seed
    
    ldp    x29, x30, [sp], #32
    ret

// =============================================
// Generate random number between 1 and max
// Input: x0 = maximum value
// Output: x0 = random number (1-max)
// =============================================
_generate_random:
    stp    x29, x30, [sp, #-16]!
    mov    x29, sp
    
    mov    x19, x0                   // Save max value
    
    // Simple Linear Congruential Generator
    adrp   x0, _random_seed@PAGE
    add    x0, x0, _random_seed@PAGEOFF
    ldr    w1, [x0]
    
    // Load 1103515245 using mov/movk combination (since it's too large for immediate)
    mov    w2, #0x5e6d               // Lower 16 bits of 1103515245
    movk   w2, #0x41c6, lsl #16      // Upper 16 bits of 1103515245
    
    mul    w1, w1, w2
    mov    w2, #12345
    add    w1, w1, w2
    str    w1, [x0]                  // Update seed
    
    // Get absolute value
    and    w1, w1, #0x7FFFFFFF
    
    // Scale to range 1-max
    udiv   w2, w1, w19               // Divide by max
    msub   w0, w2, w19, w1           // Remainder
    add    w0, w0, #1                // Make it 1-based
    
    ldp    x29, x30, [sp], #16
    ret

// =============================================
// Read input from user
// =============================================
_read_input:
    stp    x29, x30, [sp, #-16]!
    mov    x29, sp
    
    mov    x16, #3                   // read system call
    mov    x0, #0                    // stdin
    adrp   x1, input_buffer@PAGE
    add    x1, x1, input_buffer@PAGEOFF // buffer
    mov    x2, #32                   // buffer size
    svc    #0x80
    
    // Remove newline character if present
    cmp    x0, #0
    b.le   1f                       // Local label for read_done
    
    adrp   x1, input_buffer@PAGE
    add    x1, x1, input_buffer@PAGEOFF
    add    x2, x1, x0
    sub    x2, x2, #1                // Point to last character
    
    ldrb   w3, [x2]
    cmp    w3, #10                   // Check for newline
    b.ne   2f                       // Local label for read_store_len
    
    // Replace newline with null terminator
    mov    w3, #0
    strb   w3, [x2]
    sub    x0, x0, #1                // Decrease length
    
2:  // read_store_len
    adrp   x1, input_len@PAGE
    add    x1, x1, input_len@PAGEOFF
    str    x0, [x1]
    
1:  // read_done
    ldp    x29, x30, [sp], #16
    ret

// =============================================
// Parse input string to number
// Output: x0 = parsed number, -1 if invalid
// =============================================
_parse_input:
    stp    x29, x30, [sp, #-16]!
    mov    x29, sp
    
    mov    x0, #0                    // Initialize result
    adrp   x1, input_buffer@PAGE
    add    x1, x1, input_buffer@PAGEOFF // String pointer
    mov    x2, #10                   // Base 10
    
0:  // parse_loop
    ldrb   w3, [x1], #1              // Get current character and increment
    cbz    w3, 1f                    // Local label for parse_done
    
    // Check if digit
    cmp    w3, #'0'
    b.lo   2f                       // Local label for parse_invalid
    cmp    w3, #'9'
    b.hi   2f                       // Local label for parse_invalid
    
    // Convert digit and add to result
    sub    w3, w3, #'0'
    mul    x0, x0, x2
    add    x0, x0, x3
    
    b      0b                       // Back to parse_loop
    
2:  // parse_invalid
    mov    x0, #-1
    
1:  // parse_done
    ldp    x29, x30, [sp], #16
    ret

// =============================================
// Print string to stdout
// Input: x0 = null-terminated string
// =============================================
_print_string:
    stp    x29, x30, [sp, #-32]!
    mov    x29, sp
    
    mov    x19, x0                   // Save string pointer
    
    // Calculate string length
    mov    x20, #0                   // Length counter
    
0:  // length_loop
    ldrb   w1, [x19, x20]
    cbz    w1, 1f                    // Local label for length_done
    add    x20, x20, #1
    b      0b                       // Back to length_loop
    
1:  // length_done
    mov    x16, #4                   // write system call
    mov    x0, #1                    // stdout
    mov    x1, x19                   // string
    mov    x2, x20                   // length
    svc    #0x80
    
    ldp    x29, x30, [sp], #32
    ret

// =============================================
// Print number to stdout
// Input: x0 = number to print
// =============================================
_print_number:
    stp    x29, x30, [sp, #-48]!
    mov    x29, sp
    
    mov    x19, x0                   // Save number
    add    x20, sp, #16              // Use stack for buffer
    mov    x21, x20                  // Save start of buffer
    
    // Handle zero case
    cbz    x19, 0f                   // Local label for handle_zero
    
    mov    x22, #10                  // Divisor
    
1:  // convert_loop
    cbz    x19, 2f                   // Local label for print_digits
    udiv   x1, x19, x22              // Divide by 10
    msub   x2, x1, x22, x19          // Remainder
    mov    x19, x1                   // Update number
    
    add    w2, w2, #'0'              // Convert to ASCII
    strb   w2, [x20], #1             // Store digit and increment
    
    b      1b                       // Back to convert_loop
    
0:  // handle_zero
    mov    w1, #'0'
    strb   w1, [x20], #1
    
2:  // print_digits
    // Null terminate
    mov    w1, #0
    strb   w1, [x20]
    
    // Reverse the string
    mov    x0, x21                   // Start of buffer
    sub    x1, x20, #1               // End of buffer (before null terminator)
    
3:  // reverse_loop
    cmp    x0, x1
    b.ge   4f                       // Local label for reverse_done
    
    ldrb   w2, [x0]                  // Swap characters
    ldrb   w3, [x1]
    strb   w3, [x0], #1
    strb   w2, [x1], #-1
    b      3b                       // Back to reverse_loop
    
4:  // reverse_done
    mov    x0, x21                   // String to print
    bl     _print_string
    
    ldp    x29, x30, [sp], #48
    ret

// =============================================
// Time function (simple implementation)
// Input: x0 = time_t pointer (can be NULL)
// Output: x0 = current time
// =============================================
_time:
    stp    x29, x30, [sp, #-16]!
    mov    x29, sp
    
    // Load system call number using mov/movk
    mov    x16, #0x0074              // Lower 16 bits
    movk   x16, #0x2000, lsl #16     // Upper 16 bits (0x2000074 = gettimeofday)
    
    sub    sp, sp, #16
    mov    x0, sp                    // timeval structure
    mov    x1, #0                    // timezone (NULL)
    svc    #0x80
    ldr    x0, [sp]                  // Return seconds
    add    sp, sp, #16
    
    ldp    x29, x30, [sp], #16
    ret

// =============================================
// Data section
// =============================================
.section __DATA,__data

    // Constants and messages
    welcome_msg:          .asciz  "=== Number Guessing Game ===\n"
    menu_msg:             .asciz  "\nChoose difficulty:\n1. Easy (1-10, 10 attempts)\n2. Medium (1-50, 7 attempts)\n3. Hard (1-100, 5 attempts)\n4. Exit\nChoice: "
    prompt_msg:           .asciz  "Enter your guess: "
    too_high_msg:         .asciz  "Too high! Try again.\n"
    too_low_msg:          .asciz  "Too low! Try again.\n"
    win_msg:              .asciz  "\n*** Congratulations! You won! ***\n"
    lose_msg:             .asciz  "\n*** Game Over! No more attempts. ***\n"
    reveal_msg:           .asciz  "The number was: "
    attempts_msg:         .asciz  "Attempts remaining: "
    score_msg:            .asciz  "Your score: "
    play_again_msg:       .asciz  "\nPlay again? (y/n): "
    invalid_choice_msg:   .asciz  "Invalid choice! Please try again.\n"
    range_msg:            .asciz  "I'm thinking of a number between 1 and "
    newline:              .asciz  "\n"

    // Game state variables
    .align 3
    target_number:        .quad   0
    attempts_left:        .quad   0
    max_attempts:         .quad   0
    max_range:            .quad   0
    current_score:        .quad   1000
    game_won:             .quad   0

    // Input buffer
    input_buffer:         .space  32
    input_len:            .quad   0

    // Random seed
    _random_seed:         .word   0

// Required for macOS
.subsections_via_symbols